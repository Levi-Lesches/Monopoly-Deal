import "package:shared/data.dart";
import "package:shared/utils.dart";

import "game.dart";
import "interruption.dart";

sealed class PlayerAction {
  final Player player;
  const PlayerAction({required this.player});

  factory PlayerAction.fromJson(Game game, Json json) {
    final player = game.findPlayer(json["player"]);
    final name = json["name"] as String;
    if (name == "end_turn") return EndTurnAction(player: player);
    final card = game.findCard(json["card"]);
    return switch (name) {
      "bank" => BankAction(player: player, card: card),
      "charge" => ChargeAction.fromJson(game, json),
      "property" => PropertyAction(player: player, card: card as PropertyCard),
      "wild_property" => WildPropertyAction.fromJson(game, json),
      "rainbow_wild" => RainbowWildAction.fromJson(game, json),
      "set_modifier" => SetModifierAction.fromJson(game, json),
      "rent" => RentAction.fromJson(game, json),
      "steal" => StealAction.fromJson(game, json),
      "pass_go" => PassGoAction(card: card as PassGo, player: player),
      _ => throw ArgumentError("Invalid name: $name"),
    };
  }

  int get cardsUsed;

  void prehandle(Game game) { }
  void handle(Game game);
  void postHandle(Game game) { }
}

sealed class OneCardAction extends PlayerAction {
  Card get card;
  final bool shouldDiscard;
  const OneCardAction({required super.player, required this.shouldDiscard});

  @override
  int get cardsUsed => 1;

  @override
  void prehandle(Game game) {
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

  const EndTurnAction({required super.player});

  @override
  void handle(Game game) {
    if (game.interruptions.isNotEmpty) throw GameError.interruptions;
    game.endTurn();
  }
}

class BankAction extends OneCardAction {
  @override
  final Card card;
  const BankAction({
    required this.card,
    required super.player,
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
    required super.player,
    this.victim,
  }) : super(shouldDiscard: true);

  factory ChargeAction.fromJson(Game game, Json json) => ChargeAction(
    card: game.findCard(json["card"]),
    player: game.findPlayer(json["player"]),
  );

  @override
  void handle(Game game) {
    if (card.amountToPay < 0) throw PlayerException(.noRent);
    var victims = game.players;
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
  const PropertyAction({
    required this.card,
    required super.player,
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
  const WildPropertyAction({
    required this.card,
    required this.color,
    required super.player,
  }) : super(shouldDiscard: false);

  factory WildPropertyAction.fromJson(Game game, Json json) => WildPropertyAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"]),
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
  const RainbowWildAction({
    required this.card,
    required this.color,
    required super.player,
  }) : super(shouldDiscard: false);

  factory RainbowWildAction.fromJson(Game game, Json json) => RainbowWildAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"]),
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
  const SetModifierAction({
    required this.card,
    required this.color,
    required super.player,
  }) : super(shouldDiscard: false);

  factory SetModifierAction.fromJson(Game game, Json json) => SetModifierAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"]),
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
  const RentAction({
    required this.card,
    required this.color,
    required super.player,
    this.victim,
    this.doubleTheRent,
  }) : super(shouldDiscard: true);

  factory RentAction.fromJson(Game game, Json json) => RentAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"]),
  );

  @override
  int get cardsUsed => doubleTheRent == null ? 1 : 2;

  @override
  void handle(Game game) {
    var victims = game.players;
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
  final Player victim;
  final PropertyLike? toSteal;
  final PropertyLike? toGive;
  final PropertyColor? color;
  const StealAction({
    required this.card,
    required this.victim,
    required this.toSteal,
    required super.player,
    this.color,
    this.toGive,
  }) : super(shouldDiscard: true);

  factory StealAction.fromJson(Game game, Json json) => StealAction(
    card: game.findCard(json["card"]),
    victim: game.findPlayer(json["victim"]),
    player: game.findPlayer(json["player"]),
    toSteal: json.mapNullable("toSteal", game.findCard),
    color: json.mapNullable("color", PropertyColor.fromJson),
    toGive: json.mapNullable("toGive", game.findCard)
  );

  @override
  void handle(Game game) {
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
        final toGive = this.toGive;
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
  const PassGoAction({
    required this.card,
    required super.player,
  }) : super(shouldDiscard: true);

  @override
  void handle(Game game) {
    game.dealToPlayer(player, 2);
  }
}
