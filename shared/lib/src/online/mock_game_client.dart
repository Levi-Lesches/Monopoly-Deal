import "dart:async";

import "package:shared/data.dart";
import "package:shared/game.dart";

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
    _game.debugAddProperty(player, PropertyCard(color: .brown, name: "Baltic Avenue", value: 1));
    _game.debugAddProperty(player, WildPropertyCard(topColor: .brown, bottomColor: .lightBlue, value: 1), color: .brown);
    final house = House();
    final hotel = Hotel();
    _game.debugAddToHand(player, house);
    _game.debugAddToHand(player, hotel);
  }

  @override
  Future<void> dispose() async { }

  final _gameController = StreamController<GameState>.broadcast();

  @override
  Stream<GameState> get gameUpdates => _gameController.stream;

  void update() => _gameController.add(state);

  @override
  Future<void> requestState() async => update();

  @override
  Future<void> sendAction(PlayerAction action) async {
    try {
      _game.handleAction(action);
    } catch (error) {
      _gameController.addError(error);
    }
    update();
  }

  @override
  Future<void> sendResponse(InterruptionResponse response) async {
    try {
    _game.handleResponse(response);
    } catch (error) {
      _gameController.addError(error);
    }
    update();
  }

  GameState get state => _game.getStateFor(player);
}
