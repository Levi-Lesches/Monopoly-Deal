import "dart:async";

import "package:shared/data.dart";
import "package:shared/game.dart";
import "package:shared/network_data.dart";
import "package:shared/network_sockets.dart";

class MDealClient {
  final User user;
  final int roomCode;
  final ClientSocket _socket;
  MDealClient(this._socket, this.roomCode) :
    user = _socket.user;

  final _gameController = StreamController<GameState>.broadcast();
  Stream<GameState> get gameUpdates => _gameController.stream;

  StreamSubscription<void>? _sub;
  void init() {
    _sub = _socket.packets.listen(_handlePacket);
  }

  Future<void> dispose() async {
    await _gameController.close();
    await _sub?.cancel();
  }

  void _handlePacket(NetworkPacket packet) {
    switch (packet.type) {
      case "error":
        final error = MDealError.fromJson(packet.data);
        _gameController.addError(error);
      case "game_state":
        final game = GameState.fromJson(packet.data);
        _gameController.add(game);
    }
  }

  void sendResponse(InterruptionResponse response) =>
    _socket.send(NetworkPacket("game_response", response.toJson()));

  void sendAction(PlayerAction action) =>
    _socket.send(NetworkPacket("game_action", action.toJson()));

  void requestState() =>
    _socket.send(const NetworkPacket("game_request_state", {}));
}
