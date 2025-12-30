import "package:shared/data.dart";

import "game.dart";
import "interruption.dart";

sealed class PlayerAction {
  final Player player;
  const PlayerAction({required this.player});

  int get cardsUsed;

  // bool isValid(Game game);
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
