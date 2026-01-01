import "package:collection/collection.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "interruption.dart";
import "state.dart";

export "game_debug.dart";
export "game_handlers.dart";

class Game {
  final List<RevealedPlayer> players;
  List<MCard> referenceDeck = [];
  Deck deck;
  Deck discardPile;

  int playerIndex = 0;
  RevealedPlayer get currentPlayer => players[playerIndex];
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

  T findCard<T extends MCard>(String uuid) => referenceDeck
    .firstWhere((card) => card.uuid == uuid)
    as T;

  RevealedPlayer findPlayer(String name) => players
    .firstWhere((other) => other.name == name);

  GameState getStateFor(RevealedPlayer player) => GameState(
    player: player,
    otherPlayers: [
      for (final other in players.exceptFor(player))
        other.hidden,
    ],
    currentPlayer: currentPlayer.name,
    interruptions: interruptions,
    discarded: discardPile.lastOrNull,
    turnsRemaining: turnsRemaining,
  );

  void dealToPlayer(RevealedPlayer player, int count) {
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

  void steal(StealInterruption details) {
    final stealer = findPlayer(details.causedBy);
    final victim = findPlayer(details.waitingFor);
    final toSteal = findCard(details.toSteal) as PropertyLike;
    final toGive = details.toGive.map(findCard) as PropertyLike?;
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

  void discard(RevealedPlayer player, MCard card) {
    player.hand.remove(card);
    discardPile.add(card);
  }
}
