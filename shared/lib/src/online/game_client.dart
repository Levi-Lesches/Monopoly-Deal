import "dart:async";

import "package:shared/data.dart";
import "package:shared/game.dart";
import "package:shared/network.dart";
import "package:shared/utils.dart";

import "game_packets.dart";

class MDealClient {
  final User user;
  final ClientSocket _socket;
  MDealClient(this._socket) :
    user = _socket.user;

  final _gameController = StreamController<GameState>.broadcast();
  Stream<GameState> get gameUpdates => _gameController.stream;

  StreamSubscription<void>? _sub;
  Future<void> init() async {
    _sub = _socket.listen(_handlePacket);
  }

  Future<void> dispose() async {
    await _gameController.close();
    await _sub?.cancel();
  }

  Future<void> _handlePacket(Packet packet) async {
    final serverPacket = safely<GamePacket<GameServerPacketType>>(
      () => GamePacket.fromJson(packet, GameServerPacketType.fromJson),
    );
    if (serverPacket == null) return;
    switch (serverPacket.type) {
      case .error:
        final error = MDealError.fromJson(serverPacket.data);
        _gameController.addError(error);
      case .game:
        final game = GameState.fromJson(serverPacket.data);
        _gameController.add(game);
    }
  }

  Future<void> sendResponse(InterruptionResponse response) async {
    final body = GamePacket(type: GameClientPacketType.response, data: response.toJson());
    await _socket.send(body.toJson());
  }

  Future<void> sendAction(PlayerAction action) async {
    final body = GamePacket(type: GameClientPacketType.action, data: action.toJson());
    await _socket.send(body.toJson());
  }

  Future<void> requestState() async {
    const body = GamePacket(type: GameClientPacketType.game, data: {});
    await _socket.send(body.toJson());
  }
}
