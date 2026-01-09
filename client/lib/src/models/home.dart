import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:mdeal/data.dart";

import "chooser.dart";
import "model.dart";

/// The view model for the home page.
class HomeModel extends DataModel {
  final MDealClient client;
  late GameState game;
  HomeModel(this.client, this.game);

  RevealedPlayer get player => game.player;
  Choice<dynamic>? choice;

  @override
  Future<void> init() async {
    await client.requestState();
    client.gameUpdates.listen(update);
    cards.addListener(notifyListeners);
  }

  int? turnsFor(Player player) => player.name == game.currentPlayer
    ? game.turnsRemaining : null;

  void update(GameState state) {
    game = state;
    choice = null;
    notifyListeners();
    if (game.currentPlayer != player.name) return;
    unawaited(handleInterruption(game.interruption));
    if (game.interruptions.isEmpty && game.turnsRemaining > 0) {
      choice = CardChoice.play(game);
      notifyListeners();
      unawaited(cards.next.then(playCard));
    }
  }

  Future<void> handleInterruption(Interruption? interruption) async {
    switch (interruption) {
      case null: return;
      case PaymentInterruption(:final amount, :final causedBy):
        final jsn = await promptJustSayNo("$causedBy is charging you \$$amount!", forcePrompt: false);
        if (jsn != null) {
          sendResponse(JustSayNoResponse(justSayNo: jsn, player: player));
          return;
        }
        notifyListeners();
        choice = MoneyChoice(game);
        final payment = await cards.waitForList();
        final response = PaymentResponse(cards: payment, player: player);
        sendResponse(response);
      case DiscardInterruption():
        choice = CardChoice.discard(game);
        notifyListeners();
        final toDiscard = await cards.waitForList();
        final response = DiscardResponse(cards: toDiscard, player: player);
        sendResponse(response);
      case StealInterruption(:final causedBy, :final toSteal, :final toGive):
        final message = toGive == null
          ? "$causedBy wants to steal $toSteal"
          : "$causedBy wants to trade $toSteal for $toGive";
        final jsn = await promptJustSayNo(message);
        final response = jsn == null
          ? AcceptedResponse(player: player)
          : JustSayNoResponse(justSayNo: jsn, player: player);
        sendResponse(response);
      case StealStackInterruption(:final causedBy, :final color):
        final message = "$causedBy wants to steal your $color set!";
        final jsn = await promptJustSayNo(message);
        final response = jsn == null
          ? AcceptedResponse(player: player)
          : JustSayNoResponse(justSayNo: jsn, player: player);
        sendResponse(response);
      case ChooseColorInterruption(colors: final choices, :final card):
        choice = ColorChoice("Choose a color for $card", choices);
        notifyListeners();
        final color = await colors.next;
        sendResponse(ColorResponse(color: color, player: player));
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

  bool get canEndTurn {
    if (game.interruption case DiscardInterruption(:final amount)) {
      return cards.values.length >= amount;
    } else {
      return true;
    }
  }

  void sendAction(PlayerAction action) => safely(() => client.sendAction(action));
  void sendResponse(InterruptionResponse response) => safely(() => client.sendResponse(response));

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

  Future<void> playCard(MCard card) async {
    final PlayerAction action;
    if (isBanking) {
      isBanking = false;
      notifyListeners();
      sendAction(BankAction(card: card, player: player));
      return;
    }
    switch (card) {
      case MoneyCard():
        action = BankAction(card: card, player: player);
      case PropertyCard():
        action = PropertyAction(card: card, player: player);
      case PassGo():
        action = PassGoAction(card: card, player: player);
      case WildPropertyCard(:final topColor, :final bottomColor):
        choice = ColorChoice("Choose a color", [topColor, bottomColor]);
        notifyListeners();
        final color = await colors.next;
        action = WildPropertyAction(card: card, color: color, player: player);
      case RainbowWildCard():
        choice = StackChoice.rainbowWild(game);
        notifyListeners();
        final stack = await stacks.next;
        action = RainbowWildAction(card: card, color: stack.color, player: player);
      case PaymentActionCard(:final victimType):
        Player? victim;
        if (victimType == VictimType.onePlayer) {
          choice = PlayerChoice(game);
          notifyListeners();
          victim = await players.next;
        }
        action = ChargeAction(card: card, player: player, victim: victim);
      case StealingActionCard(:final canChooseSet, :final isTrade):
        if (canChooseSet) {
          choice = StackChoice.others(game);
          notifyListeners();
          final stack = await stacks.next;
          final victim = game.playerWithStack(stack);
          action = StealAction(card: card, victim: victim, color: stack.color, player: player);
        } else {
          choice = PropertyChoice.others(game);
          notifyListeners();
          final toSteal = await cards.next as PropertyLike;
          final victim = game.playerWithProperty(toSteal);
          PropertyLike? toGive;
          if (isTrade) {
            choice = PropertyChoice.self(game);
            notifyListeners();
            toGive = await cards.next as PropertyLike;
          }
          action = StealAction(card: card, victim: victim, player: player, toSteal: toSteal, toGive: toGive);
        }
      case PropertySetModifier():
        choice = StackChoice.selfSets(game);
        notifyListeners();
        final stack = await stacks.next;
        action = SetModifierAction(card: card, color: stack.color, player: player);
      case Stackable():  // covered by Property, Wild, Rainbow, House, and Hotel
        return;
      case JustSayNo():
        errorMessage = "Cannot play a Just Say No";
        notifyListeners();
        return;
      case DoubleTheRent():
        errorMessage = "Cannot play a Double the Rent";
        notifyListeners();
        return;
      case RentActionCard(:final color1, :final color2):
        choice = StackChoice.rent(game, colors: [color1, color2]);
        notifyListeners();
        final stack = await stacks.next;
        final doubler = await promptForCard<DoubleTheRent>("Use a double the rent?", forcePrompt: false);
        action = RentAction(card: card, color: stack.color, player: player, doubleTheRent: doubler);
      case RainbowRentActionCard():
        choice = StackChoice.rent(game);
        notifyListeners();
        final stack = await stacks.next;
        choice = PlayerChoice(game);
        notifyListeners();
        final victim = await players.next;
        final doubler = await promptForCard<DoubleTheRent>("Use a double the rent?", forcePrompt: false);
        action = RentAction(card: card, color: stack.color, player: player, victim: victim, doubleTheRent: doubler);
    }
    sendAction(action);
  }

  Future<JustSayNo?> promptJustSayNo(String title, {bool forcePrompt = true}) =>
    promptForCard<JustSayNo>("$title\nUse a Just Say No?", forcePrompt: forcePrompt);

  Future<T?> promptForCard<T extends MCard>(String title, {required bool forcePrompt}) async {
    final inHand = player.hand.whereType<T>().firstOrNull;
    if (inHand == null && !forcePrompt) return null;
    choice = BoolChoice(title, choices: [if (inHand != null) true, false]);
    notifyListeners();
    final confirmation = await confirmations.next;
    return confirmation ? inHand : null;
  }

  String? errorMessage;
  final cards = Chooser<MCard>();
  final colors = Chooser<PropertyColor>();
  final players = Chooser<Player>();
  final stacks = Chooser<PropertyStack>();
  final confirmations = Chooser<bool>();

  bool isBanking = false;
  void toggleBank() {
    isBanking = !isBanking;
    choice = isBanking ? CardChoice.bank(game) : CardChoice.play(game);
    notifyListeners();
  }
}
