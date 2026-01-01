import "package:shared/data.dart";
import "package:shared/utils.dart";

import "game.dart";

sealed class InterruptionResponse {
  final RevealedPlayer player;
  const InterruptionResponse({required this.player});

  factory InterruptionResponse.fromJson(Game game, Json json) => switch (json["name"] as String) {
    "payment" => PaymentResponse.fromJson(game, json),
    "justSayNo" => JustSayNoResponse.fromJson(game, json),
    "accepted" => AcceptedResponse.fromJson(game, json),
    "color" => ColorResponse.fromJson(game, json),
    "discard" => DiscardResponse.fromJson(game, json),
    _ => throw ArgumentError("Unrecognized response: $json"),
  };

  Json toJson();
}

class PaymentResponse extends InterruptionResponse {
  /* TODO: House and hotels become banked */
  final List<Card> cards;
  const PaymentResponse({
    required this.cards,
    required super.player,
  });

  factory PaymentResponse.fromJson(Game game, Json json) => PaymentResponse(
    cards: [
      for (final uuid in json["cards"])
        game.findCard(uuid),
    ],
    player: game.findPlayer(json["player"]),
  );

  @override
  Json toJson() => {
    "type": "payment",
    "cards": [for (final card in cards) card.uuid],
    "player": player.name,
  };

  void validate(int amount) {
    if (!player.hasCardsOnTable(cards)) throw GameError.notOnTable;
    if (player.netWorth < amount) {
      if (cards.length < player.cardsWithValue.length) {
        throw PlayerException(.notEnoughMoney);  // can automate this
      } else if (cards.totalValue < amount) {
        throw PlayerException(.notEnoughMoney);
      }
    }
    if (cards.any((card) => card.value == 0)) throw PlayerException(.noValue);
  }

  void handle(Game game, Player otherPlayer) {
    for (final card in cards) {
      player.removeFromTable(card);
      if (card is WildCard) {
        game.promptForColor(otherPlayer, card);
      } else {
        otherPlayer.addMoney(card);
      }
    }
  }
}

class JustSayNoResponse extends InterruptionResponse {
  final JustSayNo justSayNo;
  const JustSayNoResponse({
    required this.justSayNo,
    required super.player,
  });

  factory JustSayNoResponse.fromJson(Game game, Json json) => JustSayNoResponse(
    justSayNo: game.findCard(json["card"]),
    player: game.findPlayer(json["player"]),
  );

  void validate() {
    if (!player.hasCardsInHand([justSayNo])) throw GameError.notInHand;
  }

  @override
  Json toJson() => {
    "type": "justSayNo",
    "card": justSayNo.uuid,
    "player": player.name,
  };
}

class AcceptedResponse extends InterruptionResponse {
  const AcceptedResponse({required super.player});

  factory AcceptedResponse.fromJson(Game game, Json json) =>
    AcceptedResponse(player: game.findPlayer(json["player"]));

  @override
  Json toJson() => {
    "type": "accepted",
    "player": player.name,
  };
}

class ColorResponse extends InterruptionResponse {
  final PropertyColor color;
  const ColorResponse({
    required this.color,
    required super.player,
  });

  factory ColorResponse.fromJson(Game game, Json json) => ColorResponse(
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"]),
  );

  void validate(WildCard card) {
    switch (card) {
      case WildPropertyCard(:final topColor, :final bottomColor):
        if (color != topColor && color != bottomColor) throw PlayerException(.invalidColor);
      case RainbowWildCard():
        if (player.getStackWithRoom(color) == null) throw PlayerException(.noStack);
    }
  }

  @override
  Json toJson() => {
    "type": "color",
    "color": color.name,
    "player": player.name,
  };
}

class DiscardResponse extends InterruptionResponse {
  final List<Card> cards;
  const DiscardResponse({
    required this.cards,
    required super.player,
  });

  factory DiscardResponse.fromJson(Game game, Json json) => DiscardResponse(
    cards: [
      for (final card in (json["cards"] as List).cast<String>())
        game.findCard(card),
    ],
    player: game.findPlayer(json["player"]),
  );

  @override
  Json toJson() => {
    "type": "discard",
    "cards": [for (final card in cards) card.uuid],
    "player": player.name,
  };

  void validate(int amount) {
    if (!player.hasCardsInHand(cards)) throw GameError.notInHand;
    if (cards.length < amount) throw PlayerException(.tooManyCards);
  }
}
