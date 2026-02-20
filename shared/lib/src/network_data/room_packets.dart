import "package:shared/utils.dart";

class RoomJoinPacket {
  static const name = "room_join";
}

class RoomDetailsPacket {
  static const name = "room_details";

  final int roomCode;
  final Map<String, bool> userStatus;
  final bool gameStarted;
  const RoomDetailsPacket({
    required this.roomCode,
    required this.userStatus,
    required this.gameStarted,
  });

  RoomDetailsPacket.fromJson(Json json) :
    userStatus = (json["userStatus"] as Json).cast<String, bool>(),
    roomCode = json["roomCode"],
    gameStarted = json["gameStarted"];

  Json toJson() => {
    "roomCode": roomCode,
    "userStatus": userStatus,
    "gameStarted": gameStarted,
  };
}
