import "package:shared/data.dart";

import "game.dart";

sealed class InterruptionResponse {
  final Player player;
  const InterruptionResponse({required this.player});
}

class PaymentResponse extends InterruptionResponse {
  /* TODO: House and hotels become banked */
  final List<Card> cards;
  const PaymentResponse({
    required this.cards,
    required super.player,
  });

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

  void validate() {
    if (!player.hasCardsInHand([justSayNo])) throw GameError.notInHand;
  }
}

class AcceptedResponse extends InterruptionResponse {
  const AcceptedResponse({required super.player});
}

class ColorResponse extends InterruptionResponse {
  final PropertyColor color;
  const ColorResponse({
    required this.color,
    required super.player,
  });

  void validate(WildCard card) {
    switch (card) {
      case WildPropertyCard(:final topColor, :final bottomColor):
        if (color != topColor && color != bottomColor) throw PlayerException(.invalidColor);
      case RainbowWildCard():
        if (player.getStackWithRoom(color) == null) throw PlayerException(.noStack);
    }
  }
}

class DiscardResponse extends InterruptionResponse {
  final List<Card> cards;
  const DiscardResponse({
    required this.cards,
    required super.player,
  });

  void validate(int amount) {
    if (!player.hasCardsInHand(cards)) throw GameError.notInHand;
    if (cards.length < amount) throw PlayerException(.tooManyCards);
  }
}
