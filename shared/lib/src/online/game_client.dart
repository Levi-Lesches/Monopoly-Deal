import "dart:async";

import "package:shared/data.dart";
import "package:shared/game.dart";
import "package:shared/network.dart";

import "game_packets.dart";

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
    final serverPacket = GamePacket.fromJson(packet, GameServerPacketType.fromJson);
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
    await socket.send(body.toJson());
  }

  Future<void> sendAction(PlayerAction action) async {
    final body = GamePacket(type: GameClientPacketType.action, data: action.toJson());
    await socket.send(body.toJson());
  }

  Future<void> requestState() async {
    const body = GamePacket(type: GameClientPacketType.game, data: {});
    await socket.send(body.toJson());
  }
}
