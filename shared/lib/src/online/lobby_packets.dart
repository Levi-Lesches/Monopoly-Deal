import "package:shared/utils.dart";

class LobbyJoinPacket {
  final bool isReady;
  const LobbyJoinPacket({required this.isReady});

  LobbyJoinPacket.fromJson(Json json) :
    isReady = json["isReady"] ?? false;

  Json toJson() => {"isReady": isReady};
}

sealed class LobbyServerPacket {
  LobbyServerPacket();
  factory LobbyServerPacket.fromJson(Json json) => switch (json["type"]) {
    "accept" => LobbyAcceptPacket.fromJson(json),
    "start" => LobbyStartPacket(),
    "details" => LobbyDetailsPacket.fromJson(json),
    _ => throw ArgumentError("Invalid packet: $json"),
  };
}

class LobbyAcceptPacket extends LobbyServerPacket {
  final bool isAccepted;
  LobbyAcceptPacket({required this.isAccepted});

  LobbyAcceptPacket.fromJson(Json json) :
    isAccepted = json["isAccepted"] ?? false;

  Json toJson() => {"type": "accept", "isAccepted": isAccepted};
}

class LobbyStartPacket extends LobbyServerPacket {
  Json toJson() => {"type": "start"};
}

class LobbyDetailsPacket extends LobbyServerPacket {
  final Map<String, bool> players;
  LobbyDetailsPacket(this.players);

  LobbyDetailsPacket.fromJson(Json json) :
    players = (json["players"] as Map).cast<String, bool>();

  Json toJson() => {"type": "details", "players": players};
}
