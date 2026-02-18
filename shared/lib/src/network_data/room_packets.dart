import "package:shared/utils.dart";

class RoomDetailsPacket {
  static const name = "room_details";

  final int roomCode;
  final Map<String, bool> userStatus;
  const RoomDetailsPacket(this.roomCode, this.userStatus);

  RoomDetailsPacket.fromJson(Json json) :
    userStatus = (json["userStatus"] as Json).cast<String, bool>(),
    roomCode = json["roomCode"];

  Json toJson() => {"roomCode": roomCode, "userStatus": userStatus};
}
