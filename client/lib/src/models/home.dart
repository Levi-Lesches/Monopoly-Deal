import "dart:async";

import "package:mdeal/data.dart";

import "chooser.dart";
import "model.dart";

enum Choice {
  card,
  ownProperty,
  otherProperty,
  ownSet,
  otherSet,
  player,
}

/// The view model for the home page.
class HomeModel extends DataModel {
  RevealedPlayer get player => game.player;
  late RevealedPlayer levi;
  late RevealedPlayer david;
  late Game _game;
  late GameState game;

  Choice? choice;

  @override
  Future<void> init() async { restart(); }

  void restart() {
    levi = RevealedPlayer("Levi");
    david = RevealedPlayer("David");
    _game = Game([levi, david]);
    _game.debugAddMoney(david, MoneyCard(value: 5));
    update();
  }

  StreamSubscription<MCard>? discardSub;

  int? turnsFor(Player player) => player.name == game.currentPlayer
    ? game.turnsRemaining : null;

  void update() {
    game = _game.getStateFor(levi);
    choice = null;
    notifyListeners();
    if (game.interruptions.isEmpty && game.currentPlayer == player.name && game.turnsRemaining > 0) {
      choice = Choice.card;
      notifyListeners();
      unawaited(cards.next.then(playCard));
    } else if (canDiscard) {
      choice = Choice.card;
      notifyListeners();
      discardSub = cards.listen(toggleDiscard);
    }
  }

  void toggleDiscard(MCard card) {
    toDiscard.toggle(card);
    notifyListeners();
  }

  DiscardInterruption? get discard => game
    .interruptions
    .whereType<DiscardInterruption>()
    .where((i) => i.waitingFor == player.name)
    .firstOrNull;

  bool get canDiscard => discard != null;

  Set<MCard> toDiscard = {};

  bool get canEndTurn {
    final discard = this.discard;
    if (discard == null) return false;
    return toDiscard.length >= discard.amount;
  }

  Future<void> endTurn() async {
    _game.handleResponse(DiscardResponse(cards: toDiscard.toList(), player: player));
    toDiscard = {};
    await discardSub?.cancel();
    update();
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
    switch (card) {
      case MoneyCard():
        action = BankAction(card: card, player: player);
      case PropertyCard():
        action = PropertyAction(card: card, player: player);
      case PassGo():
        action = PassGoAction(card: card, player: player);
      // case JustSayNo():
      case WildPropertyCard(:final topColor, :final bottomColor):
        colorChoices = [topColor, bottomColor];
        notifyListeners();
        final color = await colors.next;
        action = WildPropertyAction(card: card, color: color, player: player);
      case RainbowWildCard():
        colorChoices = player.stacks
          .where((stack) => stack.isNotEmpty)
          .map((stack) => stack.color)
          .toList();
        colorChoices = [
          for (final stack in player.stacks)
            if (stack.isNotEmpty)
              stack.color,
        ];
        if (colorChoices!.isEmpty) {
          errorMessage = "Can only play a rainbow wild on an existing property stack";
          notifyListeners();
          return;
        }
        final color = await colors.next;
        action = RainbowWildAction(card: card, color: color, player: player);
      case PaymentActionCard(:final victimType):
        Player? victim;
        if (victimType == VictimType.onePlayer) {
          choice = Choice.player;
          notifyListeners();
          victim = await players.next;
        }
        action = ChargeAction(card: card, player: player, victim: victim);
      case StealingActionCard(:final canChooseSet, :final isTrade):
        choice = Choice.player;
        notifyListeners();
        final victim = await players.next;
        if (canChooseSet) {
          choice = Choice.otherSet;
          notifyListeners();
          final color = await colors.next;
          action = StealAction(card: card, victim: victim, color: color, player: player);
        } else {
          choice = Choice.otherProperty;
          notifyListeners();
          final toSteal = await properties.next;
          PropertyLike? toGive;
          if (isTrade) {
            choice = Choice.ownProperty;
            notifyListeners();
            toGive = await properties.next;
          }
          action = StealAction(card: card, victim: victim, player: player, toSteal: toSteal, toGive: toGive);
        }
      case PropertySetModifier():
        choice = Choice.ownSet;
        notifyListeners();
        final color = await colors.next;
        action = SetModifierAction(card: card, color: color, player: player);
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
      // TODO: Double the rent
      case RentActionCard(:final color1, :final color2):
        colorChoices = [color1, color2];
        notifyListeners();
        final color = await colors.next;
        action = RentAction(card: card, color: color, player: player);
      case RainbowRentActionCard():
        colorChoices = [
          for (final color in PropertyColor.values)
            if (player.rentFor(color) > 0)
              color,
        ];
        notifyListeners();
        final color = await colors.next;
        choice = Choice.player;
        final victim = await players.next;
        action = RentAction(card: card, color: color, player: player, victim: victim);
    }
    playAction(action);
  }

  String? errorMessage;
  List<PropertyColor>? colorChoices;
  final cards = Chooser<MCard>();
  final colors = Chooser<PropertyColor>();
  final properties = Chooser<PropertyLike>();
  final players = Chooser<Player>();
}
