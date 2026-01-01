import "package:shared/data.dart";
import "package:shared/utils.dart";

import "interruption.dart";

class GameState {
  final RevealedPlayer player;
  final List<HiddenPlayer> otherPlayers;

  final String currentPlayer;
  final int turnsRemaining;

  final Card? discarded;
  final List<Interruption> interruptions;

  GameState({
    required this.player,
    required this.otherPlayers,
    required this.currentPlayer,
    required this.turnsRemaining,
    required this.discarded,
    required this.interruptions,
  });

  GameState.fromJson(Json json) :
    player = RevealedPlayer.fromJson(json["player"]),
    otherPlayers = json.parseList("otherPlayers", HiddenPlayer.fromJson),
    interruptions = json.parseList("interruptions", Interruption.parse),
    currentPlayer = json["currentPlayer"],
    turnsRemaining = json["turnsRemaining"],
    discarded = json.mapNullable("discarded", cardFromJson);

  Json toJson() => {
    "type": "game",
    "player": player.toJson(),
    "otherPlayers": [
      for (final other in otherPlayers)
        other.toJson(),
    ],
    "currentPlayer": currentPlayer,
    "turnsRemaining": turnsRemaining,
    "discarded": discarded?.toJson(),
    "interruptions": [
      for (final interruption in interruptions)
        interruption.toJson(),
    ],
  };
}
