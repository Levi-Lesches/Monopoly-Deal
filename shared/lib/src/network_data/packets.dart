import "package:shared/utils.dart";

import "user.dart";

typedef RawPacket = Json;

class NetworkPacket {
  final String type;
  final RawPacket data;
  const NetworkPacket(this.type, this.data);

  NetworkPacket.fromJson(Json json) :
    type = json["type"],
    data = json["data"];

  Json toJson() => {
    "type": type,
    "data": data,
  };

  @override
  String toString() => "type=$type, data=$data";
}

typedef RoomID = int;

class WrappedPacket {
  final NetworkPacket packet;
  final User user;
  final RoomID roomCode;
  const WrappedPacket({
    required this.packet,
    required this.roomCode,
    required this.user,
  });

  WrappedPacket.fromJson(Json json) :
    packet = NetworkPacket.fromJson(json["packet"]),
    user = User.fromJson(json["user"]),
    roomCode = json["roomCode"];

  Json toJson() => {
    "packet": packet,
    "user": user,
    "roomCode": roomCode,
  };

  @override
  String toString() => "Packet from $user to room #$roomCode: $packet";
}
