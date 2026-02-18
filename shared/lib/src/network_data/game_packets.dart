// import "package:shared/game.dart";
// import "package:shared/network_data.dart";
// import "package:shared/utils.dart";

// enum GameServerPacketType {
//   game,
//   error;

//   factory GameServerPacketType.fromJson(String name) =>
//     values.byName(name);
// }

// class GamePacket<T extends Enum> extends Serializable {
//   final T type;
//   final RawPacket data;

//   const GamePacket({
//     required this.type,
//     required this.data,
//   });

//   static GamePacket response(InterruptionResponse response) => GamePacket(
//     type: GameClientPacketType.response,
//     data: response.toJson(),
//   );

//   static GamePacket action(PlayerAction action) => GamePacket(
//     type: GameClientPacketType.action,
//     data: action.toJson(),
//   );

//   static GamePacket gameRequest(PlayerAction action) => GamePacket(
//     type: GameClientPacketType.action,
//     data: action.toJson(),
//   );

//   GamePacket.fromJson(Json json, T Function(String) fromJson) :
//     type = fromJson(json["type"]),
//     data = json["data"];

//   @override
//   Json toJson() => {
//     "type": type.name,
//     "data": data,
//   };
// }
