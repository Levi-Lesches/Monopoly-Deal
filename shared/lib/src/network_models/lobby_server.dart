import "dart:async";

import "package:shared/network_data.dart";
import "package:shared/utils.dart";

import "room.dart";

class LobbyServer extends RoomEntity {
  final Map<User, bool> users = {};
  final _startCompleter = Completer<void>();

  final RoomID roomCode;
  LobbyServer(this.roomCode, super.socket);

  StreamSubscription<void>? _sub;

  Future<void> get gameStarted => _startCompleter.future;

  @override
  Iterable<User> get allUsers => users.keys;

  @override
  Future<void> dispose() async {
    if (!_startCompleter.isCompleted) {
      _startCompleter.completeError(TimeoutException("Lobby server was disposed"));
    }
    await _sub?.cancel();
  }

  void start() {
    const packet = NetworkPacket("lobby_start", {});
    sendToAll(packet);
    _startCompleter.complete();
  }

  bool get isReady => users.values.every((isReady) => isReady);

  void join(User user) {
    users[user] = false;
  }

  @override
  void broadcastToAll() {
    final details = LobbyDetailsPacket({
      for (final (user, isReady) in users.records)
        user.name: isReady,
    });
    final detailsPacket = NetworkPacket("lobby_members", details.toJson());
    sendToAll(detailsPacket);
  }

  @override
  void handlePacket(WrappedPacket wrapper) {
    final user = wrapper.user;
    if (wrapper.packet.type != LobbyReadyPacket.name) return;
    final request = LobbyReadyPacket.fromJson(wrapper.packet.data);
    users[user] = request.isReady;
    if (users.length > 1 && isReady) {
      start();
    }
    broadcastToAll();
  }
}
