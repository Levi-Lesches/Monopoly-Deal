import "dart:async";

import "package:shared/utils.dart";

import "user.dart";

typedef Packet = Json;

typedef ServerCallback = void Function(User, Packet);
abstract class ServerSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(User user, Packet payload);
  Stream<User> get disconnects;
  StreamSubscription<void> listen(ServerCallback func);
}

typedef ClientCallback = void Function(Packet);
abstract class ClientSocket {
  final User user;
  ClientSocket(this.user);

  Future<void> init();
  Future<void> dispose();
  Future<void> send(Packet payload);
  StreamSubscription<void> listen(ClientCallback func);
}

class ServerSocketPacket {
  final Packet packet;
  const ServerSocketPacket(this.packet);

  ServerSocketPacket.fromJson(Json json) :
    packet = json["packet"];

  Json toJson() => {
    "packet": packet,
  };
}

class ClientSocketPacket {
  final User user;
  final Packet packet;
  const ClientSocketPacket(this.user, this.packet);

  ClientSocketPacket.fromJson(Json json) :
    user = User.fromJson(json["user"]),
    packet = json["packet"];

  Json toJson() => {
    "user": user.toJson(),
    "packet": packet,
  };
}
