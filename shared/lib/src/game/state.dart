import "package:shared/data.dart";
import "package:shared/utils.dart";

import "interruption.dart";

class GameState {
  final RevealedPlayer player;
  final List<HiddenPlayer> otherPlayers;

  final String currentPlayer;
  final int turnsRemaining;

  final MCard? discarded;
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

  bool get canPlayWildCard => player.stacks
    .any((stack) => stack.isNotEmpty && stack.hasRoom);

  bool get othersHaveMoney => otherPlayers
    .any((player) => player.hasMoney);

  bool canPlay(MCard card) => switch(card) {
    MoneyCard() => true,
    PropertyCard() => true,
    WildPropertyCard() => true,
    RainbowWildCard() => canPlayWildCard,
    PaymentActionCard(:final victimType) => switch (victimType) {
      VictimType.allPlayers => otherPlayers.every((player) => player.hasMoney),
      VictimType.onePlayer => othersHaveMoney,
    },
    StealingActionCard(canChooseSet: true) => otherPlayers.any((player) => player.hasSet),
    StealingActionCard(:final isTrade) => otherPlayers.any((p) => p.hasPropertyToSteal)
      && (!isTrade || player.hasAProperty),
    PassGo() => true,
    House() => player.hasSet,
    Hotel() => player.stacks.any((s) => s.isSet && s.house != null),
    JustSayNo() => false,
    DoubleTheRent() => false,
    Stackable() => false,  // covered in previous cases
    RentActionCard(:final color1, :final color2) => othersHaveMoney
      && (player.rentFor(color1) > 0 || player.rentFor(color2) > 0),
    RainbowRentActionCard() => player.hasAProperty,
  };
}
