import "dart:async";

import "package:shared/data.dart";
import "package:shared/game.dart";
import "package:shared/network.dart";

import "game_client.dart";

class MockGameClient implements MDealClient {
  @override
  final User user;

  final RevealedPlayer player = RevealedPlayer("You");
  final _other = RevealedPlayer("Other");

  late final Game _game = Game([player, _other]);

  MockGameClient(this.user);

  @override
  Future<void> init() async {
    // Do whatever you want here to make a fake game setup.
    // For example, this code makes a brown set and gives the player a house and hotel
    // _game.debugAddProperty(player, PropertyCard(color: .brown, name: "Baltic Avenue", value: 1));
    // _game.debugAddProperty(player, WildPropertyCard(topColor: .brown, bottomColor: .lightBlue, value: 1), color: .brown);
    // _game.debugAddToHand(player, House());
    // _game.debugAddToHand(player, Hotel());
  }

  @override
  Future<void> dispose() async { }

  final _gameController = StreamController<GameState>.broadcast();

  @override
  Stream<GameState> get gameUpdates => _gameController.stream;

  void update() => _gameController.add(GameState.fromJson(state.toJson()));

  @override
  Future<void> requestState() async {
    // final card = PropertyCard(color: .brown, name: "Baltic Avenue", value: 1);
    // _game.debugAddToHand(player, card);
    // await Future<void>.delayed(Duration(seconds: 1));
    // _game.handleAction(PropertyAction(card: card, player: player));
    // _game.log(PropertyEvent(card: card, color: player.stacks.first.color, player: player, stackIndex: 0));
    // _game.log(BankEvent(player, player.hand.first));
    update();
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
