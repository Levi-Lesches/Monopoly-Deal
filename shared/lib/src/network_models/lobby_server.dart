import "dart:async";

import "package:shared/network_data.dart";

import "room.dart";

class LobbyServer extends RoomEntity {
  final _startCompleter = Completer<void>();

  final Room room;
  LobbyServer(this.room, super.socket);
  RoomID get roomCode => room.roomCode;

  StreamSubscription<void>? _sub;

  Future<void> get gameStarted => _startCompleter.future;

  @override
  Future<void> dispose() async {
    if (!_startCompleter.isCompleted) {
      _startCompleter.completeError(TimeoutException("Lobby server was disposed"));
    }
    await _sub?.cancel();
  }

  void start() {
    const packet = NetworkPacket("lobby_start", {});
    room.sendToAll(packet);
    _startCompleter.complete();
  }

  bool get isReady => room.users.every((user) => user.isReady);

  @override
  void broadcastToAll() {
    final details = LobbyDetailsPacket({
      for (final user in room.users)
        user.name: user.isReady,
    });
    final detailsPacket = NetworkPacket(LobbyDetailsPacket.name, details.toJson());
    room.sendToAll(detailsPacket);
  }

  @override
  void handlePacket(WrappedPacket wrapper) {
    final user = wrapper.user;
    if (wrapper.packet.type != LobbyReadyPacket.name) return;
    final request = LobbyReadyPacket.fromJson(wrapper.packet.data);
    room.getUser(user.name)?.isReady = request.isReady;
    if (room.users.length > 1 && isReady) {
      start();
    }
    broadcastToAll();
  }
}
