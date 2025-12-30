import "package:collection/collection.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "interruption.dart";
import "action.dart";
import "response.dart";

export "game_debug.dart";

class Game {
  final List<Player> players;
  Deck deck;
  Deck discardPile;

  int playerIndex = 0;
  Player get currentPlayer => players[playerIndex];
  int turnsRemaining = 0;
  List<Interruption> interruptions = [];

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

  void chargePlayers(Player player, int amount, List<Player> players) => interruptions = [
    for (final otherPlayer in players.exceptFor(player))
      if (otherPlayer.netWorth > 0)
        PaymentInterruption(amount: amount, waitingFor: otherPlayer, causedBy: player),
  ];

  void handleResponse(InterruptionResponse response) {
    final interruption = interruptions.firstWhereOrNull((other) => other.waitingFor == response.player);
    if (interruption == null) throw GameError.wrongResponse;
    switch (response) {
      case JustSayNoResponse(:final justSayNo):
        response.validate();
        discard(response.player, justSayNo);
      case PaymentResponse(:final cards):
        if (interruption is! PaymentInterruption) throw GameError.wrongResponse;
        response.validate(interruption.amount);
        for (final card in cards) {
          response.player.removeFromTable(card);
          if (card is WildCard) {
            promptForColor(interruption.causedBy, card);
          } else {
            interruption.causedBy.addMoney(card);
          }
        }
      case AcceptedResponse():  // do the thing
        switch (interruption) {
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
          case ChooseColorInterruption():
          case DiscardInterruption():
          case PaymentInterruption():
            throw GameError.wrongResponse;
        }
      case ColorResponse(:final color):
        if (interruption is! ChooseColorInterruption) throw GameError.wrongResponse;
        response.validate(interruption.card);
        response.player.addProperty(interruption.card, color);
      case DiscardResponse(:final cards):
        if (interruption is! DiscardInterruption) throw GameError.wrongResponse;
        response.validate(interruption.amount);
        for (final card in cards) {
          discard(currentPlayer, card);
        }
        playerIndex = players.nextIndex(playerIndex);
        startTurn();
    }
    interruptions.remove(interruption);
  }

  PropertyColor? promptForColor(Player player, PropertyLike card) {
    switch (card) {
      case PropertyCard(:final color): return color;
      case WildCard():
        final interruption = ChooseColorInterruption(card: card, causedBy: player);
        interruptions.add(interruption);
        return null;
      case _: return null;
    }
  }

  void endTurn() {
    if (interruptions.isNotEmpty) throw GameError("Resolve all interruptions first");
    if (turnsRemaining == 0) return;
    turnsRemaining = 0;
    interruptions.add(DiscardInterruption(amount: currentPlayer.hand.length - 7, waitingFor: currentPlayer));
  }

  void discard(Player player, Card card) {
    player.hand.remove(card);
    discardPile.add(card);
  }

  void handleAction(PlayerAction action) {
    if (interruptions.isNotEmpty) throw GameError("Respond to all interruptions before playing a card");
    if (turnsRemaining < action.cardsUsed) throw GameError("Too many cards played");
    action.prehandle(this);
    action.handle(this);
    action.postHandle(this);
    turnsRemaining -= action.cardsUsed;
    if (turnsRemaining == 0) endTurn();
  }
}
