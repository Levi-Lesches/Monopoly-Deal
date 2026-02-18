import "package:shared/utils.dart";

class LobbyReadyPacket {
  static const name = "lobby_ready";
  final bool isReady;
  const LobbyReadyPacket({required this.isReady});

  LobbyReadyPacket.fromJson(Json json) :
    isReady = json["isReady"] ?? false;

  Json toJson() => {"isReady": isReady};
}

class LobbyDetailsPacket {
  static const name = "lobby_details";
  final Map<String, bool> players;
  LobbyDetailsPacket(this.players);

  LobbyDetailsPacket.fromJson(Json json) :
    players = (json["players"] as Map).cast<String, bool>();

  Json toJson() => {"type": "details", "players": players};
}
