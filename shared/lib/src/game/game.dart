import "package:collection/collection.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "interruption.dart";
import "action.dart";
import "response.dart";

export "game_debug.dart";

class Game {
  final List<Player> players;
  List<Card> referenceDeck = [];
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
    referenceDeck = List.from(deck);
    dealStartingCards();
    startTurn();
  }

  T findCard<T extends Card>(String uuid) => referenceDeck
    .firstWhere((card) => card.uuid == uuid)
    as T;

  Player findPlayer(String name) => players
    .firstWhere((other) => other.name == name);

  Json toJson() => {
    // Only reveal information the clients can know about
    "type": "game",
    "players": [
      for (final player in players)
        player.toJson(),
    ],
    "player": currentPlayer.name,
    "discardCard": discardPile.last,
    "turnsRemaining": turnsRemaining,
    "interruptions": [
      for (final interruption in interruptions)
        interruption.toJson(),
    ]
  };

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
      case PaymentResponse():
        if (interruption is! PaymentInterruption) throw GameError.wrongResponse;
        response.validate(interruption.amount);
        response.handle(this, interruption.causedBy);
      case AcceptedResponse():  // do the thing
        switch (interruption) {
          case StealInterruption():
            steal(interruption);
          case StealStackInterruption(:final color):
            final stack = interruption.waitingFor.getStackWithSet(color)!;
            interruption.waitingFor.stacks.remove(stack);
            interruption.causedBy.stacks.add(stack);
          case _: throw GameError.wrongResponse;
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
    if (
      interruptions.isEmpty
      && turnsRemaining == 0
      && interruption is! DiscardInterruption
    ) {
      endTurn();
    }
  }

  void steal(StealInterruption details) {
    final stealer = details.causedBy;
    final victim = details.waitingFor;
    final toSteal = details.toSteal;
    final toGive = details.toGive;
    victim.removeFromTable(toSteal);
    final color = promptForColor(stealer, toSteal);
    if (color != null) stealer.addProperty(toSteal, color);
    if (toGive != null) {
      final color2 = promptForColor(victim, toGive);
      stealer.removeFromTable(toGive);
      if (color2 != null) victim.addProperty(toGive, color2);
    }
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
    if (interruptions.isEmpty && turnsRemaining == 0) endTurn();
  }
}
