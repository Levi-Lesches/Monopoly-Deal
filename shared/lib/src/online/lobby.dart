import "dart:async";

import "package:shared/network.dart";

import "lobby_packets.dart";

class LobbyClient {
  final ClientSocket socket;
  final _startCompleter = Completer<void>();
  final User user;
  LobbyClient({
    required this.socket,
    required this.user,
  });

  Future<void> get gameStarted => _startCompleter.future;
  Completer<bool>? _joinCompleter;
  StreamSubscription<void>? _sub;

  Future<void> init() async {
    _sub = socket.listen(_parsePacket);
  }

  Future<void> dispose() async {
    if (!_startCompleter.isCompleted) {
      _startCompleter.completeError(TimeoutException("Lobby client was disposed"));
    }
    if (!(_joinCompleter?.isCompleted ?? true)) {
      _joinCompleter?.completeError(TimeoutException("Lobby client was disposed"));
    }
    _joinCompleter = null;
    await _sub?.cancel();
  }

  Future<bool> join() async {
    final packet = const LobbyJoinPacket(isReady: false).toJson();
    await socket.send(packet);
    final completer = Completer<bool>();
    _joinCompleter = completer;
    return completer.future.timeout(const Duration(seconds: 5));
  }

  Future<bool> markReady() async {
    final completer = Completer<bool>();
    _joinCompleter = completer;
    const packet = LobbyJoinPacket(isReady: true);
    await socket.send(packet.toJson());
    return completer.future;
  }

  void _parsePacket(Packet packet) {
    final response = LobbyServerPacket.fromJson(packet);
    switch (response) {
      case LobbyAcceptPacket(:final isAccepted):
        _joinCompleter?.complete(isAccepted);
      case LobbyStartPacket():
        _startCompleter.complete();
    }
  }
}

class LobbyServer {
  final ServerSocket socket;
  final Map<User, bool> users = {};
  final _startCompleter = Completer<void>();
  LobbyServer(this.socket);

  StreamSubscription<void>? _sub;

  Future<void> get gameStarted => _startCompleter.future;

  Future<void> init() async {
    _sub = socket.listen(parsePacket);
  }

  Future<void> dispose() async {
    if (!_startCompleter.isCompleted) {
      _startCompleter.completeError(TimeoutException("Lobby server was disposed"));
    }
    await _sub?.cancel();
  }

  Future<void> start() async {
    for (final user in users.keys) {
      await socket.send(user, LobbyStartPacket().toJson());
    }
    _startCompleter.complete();
  }

  bool get isReady => users.values.every((isReady) => isReady);

  Future<void> parsePacket(User user, Packet packet) async {
    final request = LobbyJoinPacket.fromJson(packet);
    final isConflict = users.keys.any((other) => other.name == user.name && other.password != user.password);
    if (isConflict) {
      final response = LobbyAcceptPacket(isAccepted: false);
      await socket.send(user, response.toJson());
    } else {
      users[user] = request.isReady;
      final response = LobbyAcceptPacket(isAccepted: true);
      await socket.send(user, response.toJson());
      if (users.length > 1 && isReady) {
        await start();
      }
    }
  }
}
