import "game.dart";
import "response.dart";
import "card.dart";
import "interruptions.dart";

extension CardLogic on Game {
  Callback? handleCard(TurnChoice choice) {
    final card = choice.card;
    switch (card) {
      case MoneyCard():
        return () => currentPlayer.tableMoney.add(card);
      case PropertyCard():
        final stack = currentPlayer.getStack(card.color);
        return stack.canAdd(card) ? () => stack.add(card) : null;
      case WildPropertyCard() || RainbowWildCard() || House() || Hotel():
        final color = choice.color;
        if (color == null) return null;
        final stack = currentPlayer.getStack(color);
        return stack.canAdd(card) ? () => stack.add(card) : null;
      case RentActionCard(:final color1, :final color2):
        final color = choice.color;
        if (color == null) return null;
        if (color != color1 && color != color2) return null;
        var rent = currentPlayer.getStack(color).rent;
        if (rent == 0) return null;
        final doubleTheRent = choice.doubleTheRent;
        return () {
          if (doubleTheRent != null) {
            rent *= 2;
            discardPile.add(doubleTheRent);
          }
          chargePlayers(currentPlayer, rent, players);
          discardPile.add(card);
        };
      case RainbowRentActionCard():
        final color = choice.color;
        final victim = choice.victim;
        if (color == null || victim == null) return null;
        var rent = currentPlayer.getStack(color).rent;
        if (rent == 0) return null;
        final doubleTheRent = choice.doubleTheRent;
        return () {
          if (doubleTheRent != null) {
            rent *= 2;
            discardPile.add(doubleTheRent);
          }
          chargePlayers(currentPlayer, rent, [victim]);
          discardPile.add(card);
        };
      case PaymentActionCard(:final amountToPay, :final victimType):
        if (amountToPay == 0) return null;
        if (victimType == VictimType.onePlayer) {
          final victim = choice.victim;
          if (victim == null) return null;
          return () {chargePlayers(currentPlayer, amountToPay, [victim]); discardPile.add(card); };
        } else {
          return () {chargePlayers(currentPlayer, amountToPay, players); discardPile.add(card); };
        }
      case StealingActionCard(:final canChooseSet, :final isTrade):
        final victim = choice.victim;
        if (victim == null) return null;
        if (canChooseSet) {
          final color = choice.color;
          if (color == null) return null;
          final otherStack = victim.getStack(color);
          if (!otherStack.isSet) return null;
          final interruption = StealStackInterruption(color: color, waitingFor: victim, causedBy: currentPlayer);
          return () {interruptions = [interruption]; discardPile.add(card); };
        } else {
          final toSteal = choice.toSteal;
          if (toSteal == null) return null;
          Card? toGive;
          if (isTrade) {
            toGive = choice.toGive;
            if (toGive == null) return null;
          }
          final interruption = StealInterruption(toSteal: toSteal, toGive: toGive, waitingFor: victim, causedBy: currentPlayer);
          return () {interruptions = [interruption]; discardPile.add(card); };
        }
      case PassGo():
        return () => dealToPlayer(currentPlayer, 2);
      case JustSayNo() || DoubleTheRent():
        // Must be used as part of a [Response]
        return null;
    }
  }
}
