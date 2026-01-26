import "dart:async";

import "package:shared/data.dart";
import "package:shared/utils.dart";

import "user.dart";

typedef Packet = Json;

abstract class ServerSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(User user, Packet payload);
  Stream<User> get connections;
  Stream<User> get disconnects;
  Stream<ClientSocketPacket> get packets;
}

abstract class ClientSocket {
  final User user;
  ClientSocket(this.user);

  Future<void> init();
  Future<void> dispose();
  Future<void> send(Packet payload);
  Stream<Packet> get packets;
}

class ServerSocketPacket {
  final Packet? data;
  final GameError? error;
  const ServerSocketPacket({this.data, this.error});

  ServerSocketPacket.fromJson(Json json) :
    data = json["data"],
    error = json.mapNullable("error", GameError.fromJson);

  Json toJson() => {
    "data": data,
    "error": error?.toJson(),
  };
}

class ClientSocketPacket {
  final User user;
  final Packet data;
  const ClientSocketPacket(this.user, this.data);

  ClientSocketPacket.fromJson(Json json) :
    user = User.fromJson(json["user"]),
    data = json["data"];

  Json toJson() => {
    "user": user.toJson(),
    "data": data,
  };
}
