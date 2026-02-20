import "dart:async";

import "package:shared/data.dart";
import "package:shared/game.dart";
import "package:shared/network_data.dart";

import "game_client.dart";

class MockGameClient implements MDealClient {
  @override
  final User user;

  final RevealedPlayer player = RevealedPlayer("You");
  final _other = RevealedPlayer("Other");

  late final Game _game = Game([player, _other]);

  @override
  final int roomCode = 0;
  MockGameClient(this.user) {
    // Do whatever you want here to make a fake game setup.
    // For example, this code makes a brown set and gives the player a house and hotel
    // _game.debugAddProperty(player, PropertyCard(color: .brown, name: "Baltic Avenue", value: 1));
    // _game.debugAddProperty(player, WildPropertyCard(topColor: .lightBlue, bottomColor: .brown, value: 1), color: .brown);
    // _game.debugAddToHand(player, House());
    // _game.debugAddToHand(player, Hotel());
  }

  @override
  bool isConnected(Player player) => true;

  @override
  bool isStillPlaying = false;

  @override
  Future<void> dispose() async { }

  final _gameController = StreamController<GameState>.broadcast();

  @override
  Stream<GameState> get gameUpdates => _gameController.stream;

  void update() {
    _gameController.add(GameState.fromJson(state.toJson()));
  }

  @override
  Future<void> requestState() async {
    update();
  }

  void debug() {
    // _game.log(DealEvent(amount: 2, player: player.name));
    // _game.log(PaymentEvent(cards: [debtCollector(), Hotel()], from: _other, to: player));
    // _game.log(BankEvent(player, player.hand.first));
    // return;
    // final toSteal = player.tableStacks.first.cards.first;
    // final toGive = _other.tableStacks.first.cards.first;
    // _game.log(StealEvent(StealInterruption(causedBy: _other, waitingFor: player, toSteal: toSteal, toGive: toGive)));
    // _game.log(StealStackEvent(StealStackInterruption(causedBy: _other, waitingFor: player, color: .brown)));
    // _game.log(ActionCardEvent.charge(player: player, card: player.hand.first as PaymentActionCard));
    // _game.log(PropertyEvent(card: player.hand.last as PropertyLike, color: .brown, player: player, stackIndex: 0));
    // _game.log(JustSayNoEvent(player.name));
    // final card = player.hand.firstWhere((c) => c is PassGo);
    // _game.log(PassGoEvent(player.name, card));

    _game.interrupt(StealStackInterruption(causedBy: _other, waitingFor: player, color: .red));
  }

  @override
  Future<void> sendAction(PlayerAction action) async {
    try {
      _game.handleAction(PlayerAction.fromJson(_game, action.toJson()));
    } catch (error) {
      _gameController.addError(error);
    }
    update();
  }

  @override
  Future<void> sendResponse(InterruptionResponse response) async {
    try {
    _game.handleResponse(InterruptionResponse.fromJson(_game, response.toJson()));
    } catch (error) {
      _gameController.addError(error);
    }
    update();
  }

  GameState get state => _game.getStateFor(player);
}
