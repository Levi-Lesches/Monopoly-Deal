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
    final cards = [
      PropertyCard(color: .darkBlue, name: "Park Place", value: 4),
      PropertyCard(color: .darkBlue, name: "Boardwalk", value: 4),
      PropertyCard(color: .yellow, name: "One", value: 4),
      PropertyCard(color: .yellow, name: "Two", value: 4),
      PropertyCard(color: .brown, name: "Three", value: 4),
      PropertyCard(color: .brown, name: "Four", value: 4),
    ];
    for (final card in cards) {
      _game.debugAddProperty(_other, card);
    }
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
    _game.handleAction(action);
    update();
  }

  @override
  Future<void> sendResponse(InterruptionResponse response) async {
    _game.handleResponse(response);
    update();
  }

  GameState get state => _game.getStateFor(player);
}
