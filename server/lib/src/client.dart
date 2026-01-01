import "dart:async";

import "package:shared/shared.dart";

import "socket.dart";

class MDealClient {
  final ClientSocket socket;
  MDealClient(this.socket);

  final _gameController = StreamController<GameState>();
  Stream<GameState> get gameUpdates => _gameController.stream;

  Future<void> init() async {
    await socket.init();
    socket.listen(handlePacket);
  }

  Future<void> handlePacket(Packet packet) async {
    final type = packet["type"] as String;
    final json = packet["data"] as Json;
    switch (type) {
      case "error":
        final error = MDealError.fromJson(json);
        _gameController.addError(error);
      case "game":
        final game = GameState.fromJson(json);
        _gameController.add(game);
    }
  }

  Future<void> sendResponse(InterruptionResponse response) =>
    socket.send(response.toJson());

  Future<void> sendAction(PlayerAction action) =>
    socket.send(action.toJson());
}
