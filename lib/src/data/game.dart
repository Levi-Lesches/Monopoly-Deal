// printState() at the bottom
// ignore_for_file: avoid_print

import "package:collection/collection.dart";

import "card.dart";
import "deck.dart";
import "response.dart";
import "player.dart";
import "utils.dart";
import "interruptions.dart";
import "state.dart";

typedef Callback = void Function();

class Game {
  final List<Player> players;
  Deck deck;
  Deck discardPile;

  int playerIndex = 0;
  Player get currentPlayer => players[playerIndex];
  int turnsRemaining = 0;
  List<GameInterruption> interruptions = [];

  Game(this.players) :
    deck = shuffleDeck(),
    discardPile = []
  {
    dealStartingCards();
    startTurn();
  }

  void dealToPlayer(Player player, int count) {
    for (final _ in range(count)) {
      if (deck.isEmpty) {
        deck = discardPile.shuffled();
        discardPile = [];
      }
      player.dealCard(deck.removeLast());
    }
  }

  void dealStartingCards() {
    for (final player in players) {
      dealToPlayer(player, 5);
    }
  }

  void startTurn() {
    if (currentPlayer.hand.isEmpty) {
      dealToPlayer(currentPlayer, 5);
    } else {
      dealToPlayer(currentPlayer, 2);
    }
    turnsRemaining = 3;
  }

  void nextTurn() {
    playerIndex = players.nextIndex(playerIndex);
  }

  void chargePlayers(Player player, int amount, List<Player> players) => interruptions = [
    for (final otherPlayer in players.exceptFor(player))
      if (otherPlayer.netWorth >  0)
        PaymentInterruption(amount: amount, waitingFor: otherPlayer, causedBy: player),
  ];

  bool playCard(TurnChoice choice) {
    if (turnsRemaining < choice.cardsUsed) return false;
    if (choice.isBanked) {
      currentPlayer.hand.remove(choice.card);
      currentPlayer.tableMoney.add(choice.card);
    } else {
      final callback = handleCard(choice);
      if (callback == null) return false;
      currentPlayer.hand.remove(choice.card);
      callback();
    }
    return true;
  }

  void nextCard(TurnChoice choice) {
    turnsRemaining -= choice.cardsUsed;
    if (turnsRemaining == 0) nextTurn();
  }

  bool handleResponse(Response response) {
    final interruption = interruptions.firstWhereOrNull((other) => other.waitingFor == response.player);
    if (interruption == null) return false;
    switch (response) {
      case JustSayNoResponse(:final justSayNo):
        if (!response.isValid()) return false;
        response.player.hand.remove(justSayNo);
        discardPile.add(justSayNo);
      case PaymentResponse(:final cards):
        if (interruption case PaymentInterruption(:final amount)) {
          if (!response.isValid(amount)) return false;
          for (final card in cards) {
            response.player.removeFromTable(card);
            interruption.causedBy.addMoney(card);
          }
        } else {
          return false;
        }
      case AcceptedResponse():  // do the thing
        switch (interruption) {
          case PaymentInterruption(): return false;
          case StealInterruption(:final toSteal, :final toGive):
            interruption.waitingFor.removeFromTable(toSteal);
            final color = promptForColor(currentPlayer, toSteal);
            if (color != null) {
              interruption.causedBy.addProperty(toSteal, color);
            }
            if (toGive != null) {
              final color2 = promptForColor(interruption.waitingFor, toGive);
              interruption.causedBy.removeFromTable(toGive);
              if (color2 != null) {
                interruption.waitingFor.addProperty(toGive, color2);
              }
            }
          case StealStackInterruption(:final color):
            final stack = interruption.waitingFor.getStackWithSet(color)!;
            interruption.waitingFor.stacks.remove(stack);
            interruption.causedBy.stacks.add(stack);
          case ChooseColorInterruption(): return false;
        }
      case ColorResponse(:final color):
        if (interruption is! ChooseColorInterruption) return false;
        response.player.addProperty(interruption.card, color);
    }
    interruptions.remove(interruption);
    return true;
  }

  PropertyColor? promptForColor(Player player, Card card) {
    switch (card) {
      case PropertyCard(:final color): return color;
      case WildPropertyCard() || RainbowWildCard():
        final interruption = ChooseColorInterruption(card: card, causedBy: player);
        interruptions.add(interruption);
        return null;
      case _: return null;
    }
  }

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
}
