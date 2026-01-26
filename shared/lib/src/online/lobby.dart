import "dart:async";

import "package:shared/data.dart";
import "package:shared/network.dart";
import "package:shared/utils.dart";

import "lobby_packets.dart";

class LobbyClient {
  final ClientSocket socket;
  final _startCompleter = Completer<void>();
  final _playersController = StreamController<Map<String, bool>>.broadcast();
  final User user;
  LobbyClient(this.socket) :
    user = socket.user;

  Future<void> get gameStarted => _startCompleter.future;
  Stream<Map<String, bool>> get lobbyUsers => _playersController.stream;

  Completer<void>? _joinCompleter;
  StreamSubscription<void>? _sub;

  Future<void> init() async {
    _sub = socket.packets.listen(_parsePacket, onError: _handlePacketError);
  }

  Future<void> dispose() async {
    if (!_startCompleter.isCompleted) {
      _startCompleter.completeError(TimeoutException("started: Lobby client was disposed"));
    }
    if (!(_joinCompleter?.isCompleted ?? true)) {
      _joinCompleter?.completeError(TimeoutException("join: Lobby client was disposed"));
    }
    _joinCompleter = null;
    await _sub?.cancel();
    await _playersController.close();
  }

  Future<void> join() async {
    final packet = const LobbyJoinPacket(isReady: false).toJson();
    await socket.send(packet);
    final completer = Completer<void>();
    _joinCompleter = completer;
    return completer.future.timeout(const Duration(seconds: 1));
  }

  Future<void> markReady({required bool isReady}) async {
    final completer = Completer<void>();
    _joinCompleter = completer;
    final packet = LobbyJoinPacket(isReady: isReady);
    await socket.send(packet.toJson());
    return completer.future;
  }

  void _parsePacket(Packet packet) {
    final response = LobbyServerPacket.fromJson(packet);
    switch (response) {
      case LobbyAcceptPacket():
        _joinCompleter?.complete(null);
        _joinCompleter = null;
      case LobbyStartPacket():
        _startCompleter.complete();
      case LobbyDetailsPacket(:final players):
        _playersController.add(players);
    }
  }

  void _handlePacketError(Object error) {
    if (error is GameError) {
      _joinCompleter?.completeError(error);
      _joinCompleter = null;
    }
  }
}

class LobbyServer {
  final ServerSocket socket;
  final Map<User, bool> users = {};
  final _startCompleter = Completer<void>();
  final _controller = StreamController<User>();
  LobbyServer(this.socket);

  StreamSubscription<void>? _sub;

  Stream<User> get userStream => _controller.stream;
  Future<void> get gameStarted => _startCompleter.future;

  Future<void> init() async {
    _sub = socket.packets.listen(parsePacket);
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

  Future<void> parsePacket(ClientSocketPacket clientPacket) async {
    final ClientSocketPacket(:user, data:packet) = clientPacket;
    final request = LobbyJoinPacket.fromJson(packet);
    users[user] = request.isReady;
    _controller.add(user);
    final response = LobbyAcceptPacket();
    await socket.send(user, response.toJson());
    if (users.length > 1 && isReady) {
      await start();
    }
    final details = LobbyDetailsPacket({
      for (final (user, isReady) in users.records)
        user.name: isReady,
    });
    for (final user in users.keys) {
      await socket.send(user, details.toJson());
    }
  }
}
