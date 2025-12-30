import "package:shared/data.dart";

import "game.dart";
import "interruption.dart";
import "choice.dart";

extension GameLogic on Game {
  void handleChoice(TurnChoice choice) {
    final card = choice.card;
    switch (card) {
      case MoneyCard():
        currentPlayer.tableMoney.add(card);
      case PropertyCard():  // can always be added
        currentPlayer.addProperty(card, card.color);
      case WildPropertyCard():
        final color = choice.color;
        if (color == null) throw PlayerException(.noColor);
        currentPlayer.addProperty(card, color);
      case RainbowWildCard():
        final color = choice.color;
        if (color == null) throw PlayerException(.noColor);
        // Cannot just use [addProperty] here
        // Rainbows must be a part of an existing stack
        final stack = currentPlayer.getStackWithRoom(color);
        if (stack == null) throw PlayerException(.noStack);
        stack.add(card);
      case House() || Hotel():
        final color = choice.color;
        if (color == null) throw PlayerException(.noColor);
        final stack = currentPlayer.getStackWithSet(color);
        if (stack == null) throw PlayerException(.noSet);
        stack.add(card);
      case RentActionCard(:final color1, :final color2):
        final color = choice.color;
        if (color == null) throw PlayerException(.noColor);
        if (color != color1 && color != color2) PlayerException(.invalidColor);
        var rent = currentPlayer.rentFor(color);
        if (rent == 0) PlayerException(.noRent);
        final doubleTheRent = choice.doubleTheRent;
        if (doubleTheRent != null) {
          rent *= 2;
          discardPile.add(doubleTheRent);
        }
        chargePlayers(currentPlayer, rent, players);
        discardPile.add(card);
      case RainbowRentActionCard():
        final color = choice.color;
        if (color == null) throw PlayerException(.noColor);
        final victim = choice.victim;
        if (victim == null) throw PlayerException(.noVictim);
        var rent = currentPlayer.rentFor(color);
        if (rent == 0) throw PlayerException(.noRent);
        final doubleTheRent = choice.doubleTheRent;
        if (doubleTheRent != null) {
          rent *= 2;
          discardPile.add(doubleTheRent);
        }
        chargePlayers(currentPlayer, rent, [victim]);
        discardPile.add(card);
      case PaymentActionCard(:final amountToPay, :final victimType):
        if (amountToPay == 0) throw PlayerException(.noRent);
        var victims = players;
        if (victimType == VictimType.onePlayer) {
          final victim = choice.victim;
          if (victim == null) throw PlayerException(.noVictim);
          victims = [victim];
        }
        chargePlayers(currentPlayer, amountToPay, victims);
        discardPile.add(card);
      case StealingActionCard(:final canChooseSet, :final isTrade):
        final victim = choice.victim;
        if (victim == null) throw PlayerException(.noVictim);
        final Interruption interruption;
        if (canChooseSet) {
          final color = choice.color;
          if (color == null) throw PlayerException(.noColor);
          final otherStack = victim.getStackWithSet(color);
          if (otherStack == null) throw PlayerException(.noStack);
          interruption = StealStackInterruption(color: color, waitingFor: victim, causedBy: currentPlayer);
        } else {
          final toSteal = choice.toSteal;
          if (toSteal == null) throw PlayerException(.noCardToSteal);
          Card? toGive;
          if (isTrade) {
            toGive = choice.toGive;
            if (toGive == null) throw PlayerException(.noCardToGive);
          }
          interruption = StealInterruption(toSteal: toSteal, toGive: toGive, waitingFor: victim, causedBy: currentPlayer);
        }
        interruptions = [interruption];
        discardPile.add(card);
      case PassGo():
        dealToPlayer(currentPlayer, 2);
      case JustSayNo() || DoubleTheRent():
        // Must be used as part of a [Response]
    }
  }
}
