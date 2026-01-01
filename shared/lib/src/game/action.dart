import "package:meta/meta.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "game.dart";
import "interruption.dart";

sealed class PlayerAction {
  late final RevealedPlayer player;
  final String playerName;
  PlayerAction({required this.playerName});

  factory PlayerAction.fromJson(Game game, Json json) {
    final name = json["name"] as String;
    final playerName = json["player"];
    if (name == "end_turn") return EndTurnAction(playerName: playerName);
    final card = game.findCard(json["card"]);
    return switch (name) {
      "bank" => BankAction(playerName: playerName, card: card),
      "charge" => ChargeAction.fromJson(game, json),
      "property" => PropertyAction(playerName: playerName, card: card as PropertyCard),
      "wild_property" => WildPropertyAction.fromJson(game, json),
      "rainbow_wild" => RainbowWildAction.fromJson(game, json),
      "set_modifier" => SetModifierAction.fromJson(game, json),
      "rent" => RentAction.fromJson(game, json),
      "steal" => StealAction.fromJson(game, json),
      "pass_go" => PassGoAction(card: card as PassGo, playerName: playerName),
      _ => throw ArgumentError("Invalid name: $name"),
    };
  }

  int get cardsUsed;

  @mustCallSuper
  void prehandle(Game game) { player = game.findPlayer(playerName); }
  void handle(Game game);
  void postHandle(Game game) { }
}

sealed class OneCardAction extends PlayerAction {
  Card get card;
  final bool shouldDiscard;
  OneCardAction({required super.playerName, required this.shouldDiscard});

  @override
  int get cardsUsed => 1;

  @override
  void prehandle(Game game) {
    super.prehandle(game);
    if (!player.hasCardsInHand([card])) throw GameError.notInHand;
  }

  @override
  void postHandle(Game game) {
    player.hand.remove(card);
    if (shouldDiscard) game.discardPile.add(card);
  }
}

class EndTurnAction extends PlayerAction {
  @override
  int get cardsUsed => 0;

  EndTurnAction({required super.playerName});

  @override
  void handle(Game game) {
    if (game.interruptions.isNotEmpty) throw GameError.interruptions;
    game.endTurn();
  }
}

class BankAction extends OneCardAction {
  @override
  final Card card;
  BankAction({
    required this.card,
    required super.playerName,
  }) : super(shouldDiscard: false);

  @override
  void handle(Game game) {
    if (card.value > 0) throw PlayerException(.noValue);
    player.addMoney(card);
  }
}

class ChargeAction extends OneCardAction {
  @override
  final PaymentActionCard card;
  final Player? victim;
  ChargeAction({
    required this.card,
    required super.playerName,
    this.victim,
  }) : super(shouldDiscard: true);

  factory ChargeAction.fromJson(Game game, Json json) => ChargeAction(
    card: game.findCard(json["card"]),
    playerName: json["player"],
  );

  @override
  void handle(Game game) {
    if (card.amountToPay < 0) throw PlayerException(.noRent);
    List<Player> victims = game.players;
    if (card.victimType == VictimType.onePlayer) {
      final victim = this.victim;
      if (victim == null) throw PlayerException(.noVictim);
      if (victim.netWorth == 0) throw PlayerException(.noMoney);
      victims = [victim];
    }
    game.chargePlayers(player, card.amountToPay, victims);
  }
}

class PropertyAction extends OneCardAction {
  @override
  final PropertyCard card;
  PropertyAction({
    required this.card,
    required super.playerName,
  }) : super(shouldDiscard: false);

  @override
  void handle(Game game) {
    player.addProperty(card, card.color);
  }
}

class WildPropertyAction extends OneCardAction {
  @override
  final WildPropertyCard card;
  final PropertyColor color;
  WildPropertyAction({
    required this.card,
    required this.color,
    required super.playerName,
  }) : super(shouldDiscard: false);

  factory WildPropertyAction.fromJson(Game game, Json json) => WildPropertyAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    playerName: json["player"],
  );

  @override
  void handle(Game game) {
    if (color != card.topColor && color != card.bottomColor) throw PlayerException(.invalidColor);
    player.addProperty(card, color);
  }
}

class RainbowWildAction extends OneCardAction {
  @override
  final RainbowWildCard card;
  final PropertyColor color;
  RainbowWildAction({
    required this.card,
    required this.color,
    required super.playerName,
  }) : super(shouldDiscard: false);

  factory RainbowWildAction.fromJson(Game game, Json json) => RainbowWildAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    playerName: json["player"],
  );

  @override
  void handle(Game game) {
    // Rainbow wild cards must be part of an existing set
    final stack = player.getStackWithRoom(color);
    if (stack == null) throw PlayerException(.noStack);
    stack.add(card);
  }
}

class SetModifierAction extends OneCardAction {
  @override
  final PropertySetModifier card;
  final PropertyColor color;
  SetModifierAction({
    required this.card,
    required this.color,
    required super.playerName,
  }) : super(shouldDiscard: false);

  factory SetModifierAction.fromJson(Game game, Json json) => SetModifierAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    playerName: json["player"],
  );

  @override
  void handle(Game game) {
    final stack = player.getStackWithSet(color);
    if (stack == null) throw PlayerException(.noSet);
    stack.add(card);
  }
}

class RentAction extends OneCardAction {
  @override
  final Rentable card;
  final PropertyColor color;
  final Player? victim;
  final DoubleTheRent? doubleTheRent;
  RentAction({
    required this.card,
    required this.color,
    required super.playerName,
    this.victim,
    this.doubleTheRent,
  }) : super(shouldDiscard: true);

  factory RentAction.fromJson(Game game, Json json) => RentAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    playerName: json["player"],
  );

  @override
  int get cardsUsed => doubleTheRent == null ? 1 : 2;

  @override
  void handle(Game game) {
    List<Player> victims = game.players;
    switch (card) {
      case RentActionCard(:final color1, :final color2):
        if (color != color1 && color != color2) throw PlayerException(.invalidColor);
      case RainbowRentActionCard():
        final victim = this.victim;
        if (victim == null) throw PlayerException(.noVictim);
        if (victim.netWorth == 0) throw PlayerException(.noMoney);
        victims = [victim];
    }
    var rent = player.rentFor(color);
    if (rent == 0) throw PlayerException(.noRent);
    final doubleTheRent = this.doubleTheRent;
    if (doubleTheRent != null) {
      if (!player.hasCardsInHand([doubleTheRent])) throw GameError.notInHand;
      rent *= 2;
      game.discard(player, doubleTheRent);
    }
    game.chargePlayers(player, rent, victims);
  }
}

class StealAction extends OneCardAction {
  @override
  final StealingActionCard card;
  final String victimName;
  final PropertyLike? toSteal;
  final PropertyLike? toGive;
  final PropertyColor? color;
  StealAction({
    required this.card,
    required this.victimName,
    required this.toSteal,
    required super.playerName,
    this.color,
    this.toGive,
  }) : super(shouldDiscard: true);

  factory StealAction.fromJson(Game game, Json json) => StealAction(
    card: game.findCard(json["card"]),
    victimName: json["victim"],
    playerName: json["player"],
    toSteal: json.mapNullable("toSteal", game.findCard),
    color: json.mapNullable("color", PropertyColor.fromJson),
    toGive: json.mapNullable("toGive", game.findCard)
  );

  @override
  void handle(Game game) {
    final victim = game.findPlayer(victimName);
    if (card.canChooseSet) {
      final color = this.color;
      if (color == null) throw PlayerException(.noColor);
      final otherStack = victim.getStackWithSet(color);
      if (otherStack == null) throw PlayerException(.noSet);
      final interruption = StealStackInterruption(color: color, waitingFor: victim, causedBy: player);
      game.interruptions.add(interruption);
    } else {
      final toSteal = this.toSteal;
      if (toSteal == null) throw PlayerException(.noCardToSteal);
      if (!victim.hasCardsOnTable([toSteal])) throw GameError("Victim does not have that card");
      PropertyLike? toGive;
      if (card.isTrade) {
        toGive = this.toGive;
        if (toGive == null) throw PlayerException(.noCardToGive);
        if (!player.hasCardsOnTable([toGive])) throw GameError("Player does not have that card");
      }
      final interruption = StealInterruption(toSteal: toSteal, toGive: toGive, waitingFor: victim, causedBy: player);
      game.interruptions.add(interruption);
    }
  }
}

class PassGoAction extends OneCardAction {
  @override
  final PassGo card;
  PassGoAction({
    required this.card,
    required super.playerName,
  }) : super(shouldDiscard: true);

  @override
  void handle(Game game) {
    game.dealToPlayer(player, 2);
  }
}
