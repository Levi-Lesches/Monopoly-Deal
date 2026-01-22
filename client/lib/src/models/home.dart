import "dart:async";

import "package:flutter/widgets.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";

import "animations.dart";
import "game_choices.dart";
export "hints.dart";

/// The view model for the home page.
class HomeModel extends DataModel with AnimationModel, GameChoices, HintsModel {
  @override
  final MDealClient client;

  @override
  late GameState game;

  HomeModel(this.client, this.game);

  final scrollController = ScrollController();
  final expansionController = ExpansibleController();

  @override
  RevealedPlayer get player => game.player;

  StreamSubscription<void>? _sub;

  @override
  Future<void> init() async {
    cancelChoice(playCard: false);
    _sub = client.gameUpdates.listen(update, onError: setError);
    models.audio.addListener(notifyListeners);
    cards.addListener(notifyListeners);
    scrollController.addListener(notifyListeners);
    expansionController.addListener(notifyListeners);
    bankNotifier.addListener(notifyListeners);
    stackNotifier.addListener(notifyListeners);
    if (game.currentPlayer == player.name) {
      expansionController.expand();
    }
    unawaited(update(game));
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await client.dispose();
    cancelChoice(playCard: false);
    super.dispose();
  }

  void setError(Object error) {
    cancelChoice();
    errorMessage = error.toString();
    notifyListeners();
  }

  int? turnsFor(Player player) => player.name == game.currentPlayer
    ? game.turnsRemaining : null;

  bool winnerPopup = false;
  Future<void> update(GameState state) async {
    cancelChoice(playCard: false);
    await addEvents(state.log.reversed);
    game = state;
    notifyListeners();
    if (game.winner != null) {
      winnerPopup = true;
      return;
    }
    unawaited(handleInterruption(game.interruption));
    if (game.currentPlayer != player.name) {
      expansionController.collapse();
      return;
    }
    expansionController.expand();
    if (game.interruptions.isEmpty && game.turnsRemaining > 0) {
      choice = CardChoice.play(game);
      notifyListeners();
      unawaited(cards.next.then(playCard));
    }
  }

  List<MCard> get cardChoices => cards.values;
  void endTurn() => sendAction(EndTurnAction(player: player));

  bool get canPay {
    final interruption = game.interruption;
    if (interruption is! PaymentInterruption) return true;
    final response = PaymentResponse(cards: cardChoices, player: player);
    try {
      response.validate(interruption.amount);
      return true;
    } on MDealError {
      return false;
    }
  }

  void safely(VoidCallback func) {
    try {
      func();
      errorMessage = null;
      notifyListeners();
    } on PlayerException catch (error) {
      errorMessage = error.message;
      notifyListeners();
    } on GameError catch (error) {
      errorMessage = "Error: ${error.message}";
      notifyListeners();
    }
  }

  bool get canOrganize =>
    game.currentPlayer == player.name
    && game.interruptions.isEmpty
    && game.player.hasAProperty
    && StackChoice.move(game).choices.isNotEmpty;

  void cancelChoice({bool playCard = true}) {
    winnerPopup = false;
    isBanking = false;
    choice = null;
    notifyListeners();
    for (final chooser in choosers) {
      chooser.cancel();
    }
    if (playCard) {
      unawaited(client.requestState());
    }
  }

  Future<void> organize() async {
    cancelChoice(playCard: false);
    choice = StackChoice.move(game);
    notifyListeners();
    final stack = await stacks.next;
    choice = ConfirmCard([
      for (final card in stack.allCards)
        if (card is! PropertyCard)
          card,
    ], stack.color);
    notifyListeners();
    final card = await cards.next;
    switch (card) {
      case WildPropertyCard(:final bottomColor, :final topColor):
        choice = ColorChoice("Choose a color", [topColor, bottomColor]);
        notifyListeners();
        final color = await colors.next;
        if (color == stack.color) return cancelChoice();
        final action = MoveAction(card: card, color: color, player: player);
        sendAction(action);
      case RainbowWildCard():
        choice = StackChoice.rainbowWild(game);
        notifyListeners();
        final stack2 = await stacks.next;
        final color = stack2.color;
        if (color == stack.color) return cancelChoice();
        final action = MoveAction(card: card, color: color, player: player);
        sendAction(action);
      case House():
        choice = StackChoice.house(game);
        final stack2 = await stacks.next;
        final color = stack2.color;
        if (color == stack.color) return cancelChoice();
        final action = MoveAction(card: card, color: color, player: player);
        sendAction(action);
      case Hotel():
        choice = StackChoice.hotel(game);
        final stack2 = await stacks.next;
        final color = stack2.color;
        if (color == stack.color) return cancelChoice();
        final action = MoveAction(card: card, color: color, player: player);
        sendAction(action);
      case _:
    }
    // update(game);
  }
}
