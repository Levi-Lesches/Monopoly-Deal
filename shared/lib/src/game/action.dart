import "package:meta/meta.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "game.dart";
import "interruption.dart";

sealed class PlayerAction {
  final RevealedPlayer player;
  PlayerAction({required this.player});

  factory PlayerAction.fromJson(Game game, Json json) {
    final name = json["name"] as String;
    final player = game.findPlayer(json["player"] as String);
    if (name == "end_turn") {
      return EndTurnAction(player: player);
    } else if (name == "move") {
      return MoveAction.fromJson(game, json);
    }
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

  @mustCallSuper
  Json toJson() => {
    "name": type,
    "player": player.name,
  };

  String get type;
  int get cardsUsed;

  @mustCallSuper
  void prehandle(Game game) {  }
  void handle(Game game);
  void postHandle(Game game) { }
}

sealed class OneCardAction extends PlayerAction {
  MCard get card;
  final bool shouldDiscard;
  OneCardAction({required super.player, required this.shouldDiscard});

  @override
  Json toJson() => {
    ...super.toJson(),
    "card": card.uuid,
  };

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
  @override int get cardsUsed => 0;

  @override String get type => "end_turn";

  EndTurnAction({required super.player});

  @override
  void handle(Game game) {
    if (game.interruptions.isNotEmpty) throw GameError.interruptions;
    game.endTurn();
  }
}

class MoveAction extends PlayerAction {
  @override int get cardsUsed => 0;
  @override String get type => "move";

  final Stackable card;
  final PropertyColor color;
  MoveAction({
    required this.card,
    required this.color,
    required super.player,
  });

  factory MoveAction.fromJson(Game game, Json json) => MoveAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"]),
  );

  @override
  Json toJson() => {
    ...super.toJson(),
    "card": card.uuid,
    "color": color.name,
  };

  @override
  void handle(Game game) {
    final fromStack = player.getStackWithCard(card);
    switch (card) {
      case WildPropertyCard() || RainbowWildCard():
        if (fromStack.cards.exceptFor(card as PropertyLike).every((c) => c is RainbowWildCard)) {
          throw GameError("That would leave only rainbow cards on ${fromStack.color}");
        }
        fromStack.remove(player, card);
        player.addProperty(card, color);
      case House():
        fromStack.house = null;
        final toStack = player.getStackWithSet(color)!;
        toStack.add(card);
        final hotel = fromStack.hotel;
        if (hotel != null) {
          fromStack.hotel = null;
          toStack.hotel = hotel;
        }
      case Hotel():
        fromStack.hotel = null;
        final toStack = player.getStackWithSet(color)!;
        toStack.add(card);
    }
    game.log("$player moved $card to $color");
  }
}

class BankAction extends OneCardAction {
  @override
  String get type => "bank";

  @override
  final MCard card;

  BankAction({
    required this.card,
    required super.player,
  }) : super(shouldDiscard: false);

  @override
  void handle(Game game) {
    if (card.value == 0) throw PlayerException(.noValue);
    if (card is PropertyLike) throw PlayerException(.noColor);
    player.addMoney(card);
    if (card is MoneyCard) {
      game.log("$player played $card");
    } else {
      game.log("$player banked $card");
    }
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
    player: game.findPlayer(json["player"] as String),
    victim: json.mapNullable("victim", game.findPlayer),
  );

  @override
  String get type => "charge";

  @override
  Json toJson() => {
    ...super.toJson(),
    "victim": victim?.name,
  };

  @override
  void handle(Game game) {
    if (card.amountToPay < 0) throw PlayerException(.noRent);
    List<Player> victims = game.players;
    if (card.victimType == VictimType.onePlayer) {
      final victim = this.victim;
      if (victim == null) throw PlayerException(.noVictim);
      if (victim.netWorth == 0) throw PlayerException(.noMoney);
      victims = [victim];
      game.log("$player paid a $card against $victim");
    } else {
      game.log("$player paid a $card");
    }
    game.chargePlayers(player, card.amountToPay, victims);
  }
}

class PropertyAction extends OneCardAction {
  @override
  final PropertyCard card;
  PropertyAction({
    required this.card,
    required super.player,
  }) : super(shouldDiscard: false);

  @override
  String get type => "property";

  @override
  void handle(Game game) {
    player.addProperty(card, card.color);
    game.log("$player played $card");
  }
}

class WildPropertyAction extends OneCardAction {
  @override
  final WildPropertyCard card;
  final PropertyColor color;

  WildPropertyAction({
    required this.card,
    required this.color,
    required super.player,
  }) : super(shouldDiscard: false);

  @override
  String get type => "wild_property";

  factory WildPropertyAction.fromJson(Game game, Json json) => WildPropertyAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"] as String),
  );

  @override
  Json toJson() => {
    ...super.toJson(),
    "color": color.name,
  };

  @override
  void handle(Game game) {
    if (color != card.topColor && color != card.bottomColor) throw PlayerException(.invalidColor);
    player.addProperty(card, color);
    game.log("$player played a $card as a $color");
  }
}

class RainbowWildAction extends OneCardAction {
  @override
  final RainbowWildCard card;
  final PropertyColor color;
  RainbowWildAction({
    required this.card,
    required this.color,
    required super.player,
  }) : super(shouldDiscard: false);

  factory RainbowWildAction.fromJson(Game game, Json json) => RainbowWildAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"] as String),
  );

  @override
  String get type => "rainbow_wild";

  @override
  Json toJson() => {
    ...super.toJson(),
    "color": color.name,
  };

  @override
  void handle(Game game) {
    // Rainbow wild cards must be part of an existing set
    final stack = player.getStackWithRoom(color);
    if (stack == null) throw PlayerException(.noStack);
    stack.add(card);
    game.log("$player played a $card as a $color");
  }
}

class SetModifierAction extends OneCardAction {
  @override
  final PropertySetModifier card;
  final PropertyColor color;
  SetModifierAction({
    required this.card,
    required this.color,
    required super.player,
  }) : super(shouldDiscard: false);

  factory SetModifierAction.fromJson(Game game, Json json) => SetModifierAction(
    card: game.findCard(json["card"]),
    color: PropertyColor.fromJson(json["color"]),
    player: game.findPlayer(json["player"] as String),
  );

  @override
  String get type => "set_modifier";

  @override
  Json toJson() => {
    ...super.toJson(),
    "color": color.name,
  };

  @override
  void handle(Game game) {
    if (!color.isNormal) throw PlayerException(.invalidColor);
    final stack = player.getStackWithSet(color);
    if (stack == null) throw PlayerException(.noSet);
    stack.add(card);
    game.log("$player added a $card to their $color stack");
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
    required super.player,
    this.victim,
    this.doubleTheRent,
  }) : super(shouldDiscard: true);

  factory RentAction.fromJson(Game game, Json json) => RentAction(
    card: game.findCard(json["card"]),
    player: game.findPlayer(json["player"] as String),
    color: PropertyColor.fromJson(json["color"]),
    doubleTheRent: json.mapNullable("doubleTheRent", game.findCard),
    victim: json.mapNullable("victim", game.findPlayer),
  );

  @override
  String get type => "rent";

  @override
  Json toJson() => {
    ...super.toJson(),
    "color": color.name,
    "doubleTheRent": doubleTheRent?.uuid,
    "victim": victim?.name,
  };

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
      game.log("$player used a double the rent!");
    }
    game.log("$player is charging rent for $color (\$$rent)");
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
  StealAction({
    required this.card,
    required this.victim,
    required super.player,
    this.toSteal,
    this.color,
    this.toGive,
  }) : super(shouldDiscard: true);

  factory StealAction.fromJson(Game game, Json json) => StealAction(
    card: game.findCard(json["card"]),
    player: game.findPlayer(json["player"] as String),
    victim: game.findPlayer(json["victim"]),
    toSteal: json.mapNullable("toSteal", game.findCard),
    color: json.mapNullable("color", PropertyColor.fromJson),
    toGive: json.mapNullable("toGive", game.findCard)
  );

  @override
  String get type => "steal";

  @override
  Json toJson() => {
    ...super.toJson(),
    "victim": victim.name,
    "toSteal": toSteal?.uuid,
    "color": color?.name,
    "toGive": toGive?.uuid,
  };

  @override
  void handle(Game game) {
    if (card.canChooseSet) {
      final color = this.color;
      if (color == null) throw PlayerException(.noColor);
      final otherStack = victim.getStackWithSet(color);
      if (otherStack == null) throw PlayerException(.noSet);
      final interruption = StealStackInterruption(color: color, waitingFor: victim, causedBy: player);
      game.interrupt(interruption);
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
      game.interrupt(interruption);
    }
  }
}

class PassGoAction extends OneCardAction {
  @override
  final PassGo card;

  PassGoAction({
    required this.card,
    required super.player,
  }) : super(shouldDiscard: true);

  @override
  String get type => "pass_go";

  @override
  void handle(Game game) {
    game.dealToPlayer(player, 2);
    game.log("$player played a Pass Go");
  }
}
