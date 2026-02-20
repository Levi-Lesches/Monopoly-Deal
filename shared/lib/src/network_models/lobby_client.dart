import "dart:async";

import "package:shared/data.dart";
import "package:shared/network_data.dart";
import "package:shared/network_sockets.dart";

class LobbyClient {
  final ClientSocket socket;
  final User user;
  LobbyClient(this.socket) :
    user = socket.user;

  final _startCompleter = Completer<void>();
  final _playersController = StreamController<Map<String, bool>>.broadcast();

  Completer<RoomID>? _joinCompleter;
  StreamSubscription<void>? _sub;

  Future<void> get gameStarted => _startCompleter.future;
  Stream<Map<String, bool>> get lobbyUsers => _playersController.stream;

  void init() {
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

  Future<RoomID> join(RoomID? roomCode) {
    socket.roomCode = roomCode ?? 0;
    socket.send(const NetworkPacket(RoomJoinPacket.name, {}));
    final completer = Completer<RoomID>();
    _joinCompleter = completer;
    return completer.future.timeout(const Duration(seconds: 1));
  }

  void markReady({required bool isReady}) {
    final packet = LobbyReadyPacket(isReady: isReady);
    socket.send(NetworkPacket(LobbyReadyPacket.name, packet.toJson()));
  }

  void _parsePacket(NetworkPacket packet) {
    if (packet.type == "lobby_start") {
      _startCompleter.complete();
    } else if (packet.type == LobbyDetailsPacket.name) {
      final details = LobbyDetailsPacket.fromJson(packet.data);
      _playersController.add(details.players);
    } else if (packet.type == RoomDetailsPacket.name) {
      final details = RoomDetailsPacket.fromJson(packet.data);
      socket.roomCode = details.roomCode;
      _joinCompleter?.complete(details.roomCode);
      _joinCompleter = null;
      if (details.gameStarted) _startCompleter.complete();
    }
  }

  void _handlePacketError(Object error) {
    if (error is GameError) {
      _joinCompleter?.completeError(error);
      _joinCompleter = null;
    }
  }
}
