// This file prints debug info
// ignore_for_file: avoid_print

import "package:meta/meta.dart";
import "package:shared/data.dart";

import "game.dart";

extension GameDebugUtils on Game {
  void printState() {
    print("=======================================");
    print("Game State: $currentPlayer's turn, $turnsRemaining cards left");
    for (final interruption in interruptions) {
      print("  - $interruption");
    }
    print("  - There are ${deck.length} cards in the deck and ${discardPile.length} cards in the discard pile");
    print("  - The top card of the discard pile is ${discardPile.lastOrNull}");
    for (final player in players) {
      print("  - $player's stats: Net Worth: \$${player.netWorth}");
      print("    - ${player.hand.length} cards in their hand: ${player.hand}");
      final properties = [
        for (final stack in player.stacks)
          for (final card in stack.cards)
            if (card is! House && card is! Hotel)
              card,
      ];
      print("    - Properties: $properties");
      print("    - Money (\$${player.tableMoney.totalValue}): ${player.tableMoney}");
    }
  }

  @visibleForTesting
  void debugAddToHand(RevealedPlayer player, Card card) {
    referenceDeck.add(card);
    player.hand.add(card);
  }

  @visibleForTesting
  void debugAddMoney(RevealedPlayer player, Card card) {
    referenceDeck.add(card);
    player.addMoney(card);
  }
}
