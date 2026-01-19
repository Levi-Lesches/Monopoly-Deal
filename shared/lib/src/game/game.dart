import "package:collection/collection.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "event.dart";
import "interruption.dart";
import "state.dart";

export "game_debug.dart";
export "game_handlers.dart";

class Game {
  final List<RevealedPlayer> players;
  final List<GameEvent> _log = [];

  final List<MCard> referenceDeck = [];
  Deck deck;
  Deck discardPile;

  int playerIndex = 0;
  RevealedPlayer get currentPlayer => players[playerIndex];
  int turnsRemaining = 0;
  final interruptions = <Interruption>[];

  Game(this.players) :
    deck = shuffleDeck(),
    discardPile = []
  {
    referenceDeck.addAll(deck);
    log(const SimpleEvent("Starting the game!"));
    dealStartingCards();
    startTurn();
  }

  T findCard<T extends MCard>(CardUuid uuid) => referenceDeck
    .firstWhere((card) => card.uuid == uuid)
    as T;

  RevealedPlayer findPlayer(String name) => players
    .firstWhere((other) => other.name == name);

  GameState getStateFor(RevealedPlayer player) => GameState(
    player: player,
    numCards: deck.length,
    otherPlayers: [
      for (final other in players.exceptFor(player))
        other.hidden,
    ],
    playerOrder: [
      for (final anyPlayer in players)
        anyPlayer.name,
    ],
    currentPlayer: currentPlayer.name,
    interruptions: interruptions,
    discarded: discardPile.lastOrNull,
    turnsRemaining: turnsRemaining,
    log: _log.reversed.take(20).toList(),
  );

  void dealToPlayer(RevealedPlayer player, int count) {
    for (final _ in range(count)) {
      if (deck.isEmpty) {
        deck = discardPile.shuffled();
        discardPile = [];
      }
      player.dealCard(deck.removeLast());
    }
    log(DealEvent(amount: count, player: player.name));
  }

  void dealStartingCards() {
    for (final player in players) {
      dealToPlayer(player, 5);
    }
  }

  void startTurn() {
    final numCards = currentPlayer.handCount == 0 ? 5 : 2;
    dealToPlayer(currentPlayer, numCards);
    turnsRemaining = 3;
  }

  void chargePlayers(Player player, int amount, List<Player> players) {
    for (final otherPlayer in players.exceptFor(player)) {
      if (otherPlayer.netWorth == 0) continue;
      final interruption = PaymentInterruption(amount: amount, waitingFor: otherPlayer, causedBy: player);
      interrupt(interruption);
    }
  }

  void steal(StealInterruption details) {
    final stealer = findPlayer(details.causedBy);
    final victim = findPlayer(details.waitingFor);
    final toSteal = findCard(details.toSteal) as PropertyLike;
    if (!victim.hasCardsOnTable([toSteal])) throw GameError.notOnTable;
    final toGive = details.toGive.map(findCard) as PropertyLike?;
    victim.removeFromTable(toSteal);
    log(StealEvent(details));
    final color = promptForColor(stealer, toSteal);
    if (color != null) stealer.addProperty(toSteal, color);
    if (toGive != null) {
      final color2 = promptForColor(victim, toGive);
      stealer.removeFromTable(toGive);
      if (color2 != null) victim.addProperty(toGive, color2);
      log(SimpleEvent("$stealer gave $toGive to $victim"));
    }
  }

  PropertyColor? promptForColor(Player player, PropertyLike card) {
    switch (card) {
      case PropertyCard(:final color): return color;
      case WildPropertyCard(:final topColor, :final bottomColor):
        interrupt(ChooseColorInterruption(card: card, causedBy: player, colors: [topColor, bottomColor]));
        return null;
      case RainbowWildCard():
        final colors = [
          for (final stack in player.stacks)
            if (stack.hasRoom)
              stack.color,
        ];
        interrupt(ChooseColorInterruption(card: card, causedBy: player, colors: colors));
        return null;
      case _: return null;
    }
  }

  void interrupt(Interruption interruption) => interruptions.add(interruption);

  void log(GameEvent event) => _log.add(event);

  void endTurn() {
    if (interruptions.isNotEmpty) throw GameError("Resolve all interruptions first");
    log(SimpleEvent("$currentPlayer ended their turn"));
    turnsRemaining = 0;
    var amountToDiscard = currentPlayer.handCount - 7;
    if (amountToDiscard < 0) amountToDiscard = 0;
    interrupt(DiscardInterruption(amount: amountToDiscard, waitingFor: currentPlayer));
  }

  void discard(RevealedPlayer player, MCard card) {
    player.hand.remove(card);
    discardPile.add(card);
  }
}
