// ignore_for_file: invalid_use_of_visible_for_testing_member

import "dart:async";

import "package:collection/collection.dart";
import "package:mdeal/data.dart";

import "chooser.dart";
import "model.dart";

/// The view model for the home page.
class HomeModel extends DataModel {
  final MDealClient client;
  HomeModel(this.client);

  RevealedPlayer get player => game.player;
  late RevealedPlayer levi;
  late RevealedPlayer david;
  late Game _game;
  late GameState game;

  Choice<dynamic>? choice;

  @override
  Future<void> init() async { restart(); }

  void restart() {
    levi = RevealedPlayer("Levi");
    david = RevealedPlayer("David");
    _game = Game([levi, david]);
    _game.debugAddMoney(david, MoneyCard(value: 5));
    _game.debugAddProperty(levi, PropertyCard(name: "Boardwalk", color: PropertyColor.darkBlue));
    _game.debugAddProperty(levi, PropertyCard(name: "Park Place", color: PropertyColor.darkBlue));
    _game.debugAddProperty(david, PropertyCard(name: "Reading Railroad", color: PropertyColor.railroads));
    _game.debugAddProperty(david, PropertyCard(name: "B&O Railroad", color: PropertyColor.railroads));
    _game.debugAddToHand(levi, RainbowRentActionCard());
    _game.debugAddToHand(levi, DoubleTheRent());
    _game.debugAddToHand(levi, slyDeal());
    update();
  }

  StreamSubscription<MCard>? discardSub;

  int? turnsFor(Player player) => player.name == game.currentPlayer
    ? game.turnsRemaining : null;

  void update() {
    game = _game.getStateFor(levi);
    // choice = null;
    choice = null;
    notifyListeners();
    if (game.currentPlayer != player.name) return;
    if (game.interruptions.isEmpty && game.turnsRemaining > 0) {
      // choice = Choice.card;
      choice = CardChoice.play(game);
      notifyListeners();
      unawaited(cards.next.then(playCard));
    } else if (isDiscarding) {
      // choice = Choice.card;
      choice = CardChoice.discard(game);
      notifyListeners();
      discardSub = cards.listen(toggleDiscard);
    }
  }

  bool get isDiscarding => discard != null;
  final Set<MCard> toDiscard = {};
  void toggleDiscard(MCard card) {
    toDiscard.toggle(card);
    notifyListeners();
  }

  DiscardInterruption? get discard => game
    .interruptions
    .whereType<DiscardInterruption>()
    .where((i) => i.waitingFor == player.name)
    .firstOrNull;

  bool get canEndTurn {
    final discard = this.discard;
    if (discard == null) return true;
    return toDiscard.length >= discard.amount;
  }

  Future<void> endTurn() async {
    cards.cancel();
    final discard = this.discard;
    if (discard != null) {
      _game.handleResponse(DiscardResponse(cards: toDiscard.toList(), player: player));
      toDiscard.clear();
      await discardSub?.cancel();
      update();
    } else {
      playAction(EndTurnAction(player: player));
    }
  }

  void playAction(PlayerAction action) {
    try {
      _game.handleAction(action);
      errorMessage = null;
      notifyListeners();
    } on PlayerException catch (error) {
      errorMessage = error.message;
      notifyListeners();
    } on GameError catch (error) {
      errorMessage = "Error: ${error.message}";
      notifyListeners();
    }
    update();
  }

  Future<void> playCard(MCard card) async {
    final PlayerAction action;
    if (isBanking) {
      isBanking = false;
      notifyListeners();
      playAction(BankAction(card: card, player: player));
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
        choice = ColorChoice([topColor, bottomColor]);
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
          // choice = Choice.player;
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
            toGive = await properties.next;
          }
          action = StealAction(card: card, victim: victim, player: player, toSteal: toSteal, toGive: toGive);
        }
      case PropertySetModifier():
        // choice = Choice.ownSet;
        choice = StackChoice.selfSets(game);
        notifyListeners();
        final stack = await stacks.next;
        action = SetModifierAction(card: card, color: stack.color, player: player);
      case Stackable():  // covered by Property, Wild, Rainbow, House, and Hotel
        return;
      case JustSayNo():
        errorMessage = "Cannot play a Just Say No";
        notifyListeners();
        update();
        return;
      case DoubleTheRent():
        errorMessage = "Cannot play a Double the Rent";
        notifyListeners();
        update();
        return;
      case RentActionCard(:final color1, :final color2):
        choice = StackChoice.rent(game, colors: [color1, color2]);
        notifyListeners();
        final stack = await stacks.next;
        final doubler = await getDoubler();
        action = RentAction(card: card, color: stack.color, player: player, doubleTheRent: doubler);
      case RainbowRentActionCard():
        choice = StackChoice.rent(game);
        notifyListeners();
        final stack = await stacks.next;
        choice = PlayerChoice(game);
        notifyListeners();
        final victim = await players.next;
        final doubler = await getDoubler();
        action = RentAction(card: card, color: stack.color, player: player, victim: victim, doubleTheRent: doubler);
    }
    playAction(action);
  }

  Future<DoubleTheRent?> getDoubler() async {
    final doublerInHand = player.hand.whereType<DoubleTheRent>().firstOrNull;
    if (doublerInHand == null) return null;
    choice = BoolChoice("Use a double the rent?");
    notifyListeners();
    final confirmation = await confirmations.next;
    return confirmation ? doublerInHand : null;
  }

  String? errorMessage;
  final cards = Chooser<MCard>();
  final colors = Chooser<PropertyColor>();
  final properties = Chooser<PropertyLike>();
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
