import "dart:async";

import "package:shared/data.dart";
import "package:shared/network_data.dart";

const protocolName = "monopoly-deal.forgot-semicolon.com";

abstract class ClientSocket {
  final User user;
  ClientSocket(this.user);

  int roomCode = 0;

  Future<void> init();
  Future<void> dispose();
  void send(NetworkPacket payload);
  Stream<NetworkPacket> get packets;
  bool get isConnected;

  WrappedPacket wrap(NetworkPacket packet) => WrappedPacket(
    packet: packet,
    user: user,
    roomCode: roomCode,
  );
}

class DisconnectionEvent {
  final User user;
  final int roomCode;
  const DisconnectionEvent({
    required this.user,
    required this.roomCode,
  });
}

abstract class ServerSocket {
  Future<void> init();
  Future<void> dispose();

  Stream<WrappedPacket> get packets;
  void send(User user, NetworkPacket packet);
  void sendError(User user, MDealError error) => send(user, NetworkPacket("error", error.toJson()));

  Stream<DisconnectionEvent> get disconnections;
}
