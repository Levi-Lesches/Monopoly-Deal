import "dart:async";

import "package:shared/shared.dart";

import "socket.dart";

class MDealClient {
  final User user;
  final ClientSocket socket;
  MDealClient(this.socket, this.user);

  final _gameController = StreamController<GameState>.broadcast();
  Stream<GameState> get gameUpdates => _gameController.stream;

  Future<void> init() async {
    await socket.init();
    socket.listen(handlePacket);
  }

  Future<void> dispose() async {
    await socket.dispose();
    await _gameController.close();
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

  Future<void> sendResponse(InterruptionResponse response) async {
    final body = {
      "type": "response",
      "data": response.toJson(),
      "password": user.password,
    };
    await socket.send(body);
  }

  Future<void> sendAction(PlayerAction action) async {
    final body = {
      "type": "action",
      "data": action.toJson(),
      "password": user.password,
    };
    await socket.send(body);
  }
}
