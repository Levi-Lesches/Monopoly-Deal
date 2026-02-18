import "dart:async";
import "dart:math";
import "package:collection/collection.dart";

import "package:shared/network_data.dart";
import "package:shared/network_sockets.dart";

import "lobby_server.dart";
import "game_server.dart";

abstract class RoomEntity {
  final ServerSocket socket;
  RoomEntity(this.socket);

  Iterable<User> get allUsers;

  Future<void> dispose() async { }

  void handlePacket(WrappedPacket wrapper);
  void broadcastToAll();
  void sendToAll(NetworkPacket packet) {
    for (final user in allUsers) {
      socket.send(user, packet);
    }
  }
}

class Room {
  final ServerSocket socket;
  final int roomCode;
  final List<User> users = [];
  late RoomEntity currentEntity;  // lobby or game

  Room(this.socket) :
    roomCode = Random().nextInt(9998) + 1;  // [0, 9999]

  StreamSubscription<WrappedPacket>? _packetSub;
  StreamSubscription<DisconnectionEvent>? _disconnectionSub;

  void init() {
    _packetSub = socket.packets
      .where((packet) => packet.roomCode == roomCode)
      .listen(handlePacket);

    _disconnectionSub = socket.disconnections
      .where((event) => event.roomCode == roomCode)
      .listen(handleDisconnection);

    final lobby = LobbyServer(roomCode, socket);
    unawaited(lobby.gameStarted.then(startGame, onError: dispose));
    currentEntity = lobby;
  }

  Future<void> dispose([_]) async {
    await currentEntity.dispose();
    await _packetSub?.cancel();
    await _disconnectionSub?.cancel();
  }

  User? getUser(String name) => users.firstWhereOrNull((other) => other.name == name);

  void handlePacket(WrappedPacket packet) {
    currentEntity.handlePacket(packet);
  }

  bool join(User user) {
    final name = user.name;
    final other = getUser(name);
    if (other == null) {
      // A new user is joining
      if (currentEntity case final LobbyServer lobby) {
        users.add(user);
        lobby.join(user);
      } else {
        return false;
      }
    } else if (other.isConnected) {
      // User is trying to take another's place!
      return false;
    } else {
      // User is re-joining after disconnecting
      other.isConnected = true;
    }
    currentEntity.broadcastToAll();
    broadcastRoomDetails();
    return true;
  }

  void handleDisconnection(DisconnectionEvent event) {
    final user = getUser(event.user.name);
    if (user == null) return;
    if (!user.isConnected) return;
    user.isConnected = false;
    broadcastRoomDetails();
  }

  void broadcastRoomDetails() {
    final packet = RoomDetailsPacket(roomCode, {
      for (final user in users)
        user.name: user.isConnected,
    });
    sendToAll(NetworkPacket(RoomDetailsPacket.name, packet.toJson()));
  }

  void sendToAll(NetworkPacket packet) {
    for (final user in users) {
      socket.send(user, packet);
    }
  }

  Future<void> startGame([_]) async {
    await currentEntity.dispose();
    final game = GameServer(users, socket);
    game.broadcastToAll();
    unawaited(game.isFinished.then(dispose));
    currentEntity = game;
  }
}
