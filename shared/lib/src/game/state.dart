import "package:collection/collection.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "interruption.dart";

class GameState {
  final RevealedPlayer player;
  final List<HiddenPlayer> otherPlayers;
  final List<String> playerOrder;

  List<Player> get allPlayers => [
    for (final name in playerOrder)
      if (player.name == name)
        player
      else
        otherPlayers.firstWhere((p) => p.name == name),
  ];

  final String currentPlayer;
  final int turnsRemaining;

  final MCard? discarded;
  final List<Interruption> interruptions;
  final List<String> log;

  GameState({
    required this.player,
    required this.otherPlayers,
    required this.playerOrder,
    required this.currentPlayer,
    required this.turnsRemaining,
    required this.discarded,
    required this.interruptions,
    required this.log,
  });

  Interruption? interruptionFor(Player other) => interruptions
    .firstWhereOrNull((i) => i.waitingFor == other.name);

  int get turnsUsed => 3 - turnsRemaining;

  bool get isDiscarding => interruptions
    .whereType<DiscardInterruption>()
    .isNotEmpty;

  Interruption? get interruption => interruptionFor(player);

  GameState.fromJson(Json json) :
    player = RevealedPlayer.fromJson(json["player"]),
    otherPlayers = json.parseList("otherPlayers", HiddenPlayer.fromJson),
    playerOrder = (json["playerOrder"] as List).cast<String>(),
    interruptions = json.parseList("interruptions", Interruption.parse),
    currentPlayer = json["currentPlayer"],
    turnsRemaining = json["turnsRemaining"],
    discarded = json.mapNullable("discarded", cardFromJson),
    log = (json["log"] as List).cast<String>();

  Json toJson() => {
    "player": player.toJson(),
    "otherPlayers": [
      for (final other in otherPlayers)
        other.toJson(),
    ],
    "playerOrder": playerOrder,
    "currentPlayer": currentPlayer,
    "turnsRemaining": turnsRemaining,
    "discarded": discarded?.toJson(),
    "interruptions": [
      for (final interruption in interruptions)
        interruption.toJson(),
    ],
    "log": log,
  };

  bool get canPlayWildCard => player.stacks
    .any((stack) => stack.isNotEmpty && stack.hasRoom);

  bool get othersHaveMoney => otherPlayers
    .any((player) => player.hasMoney);

  Player playerWithStack(PropertyStack stack) => otherPlayers
    .firstWhere((p) => p.stacks.contains(stack));

  Player playerWithProperty(PropertyLike card) => otherPlayers
    .firstWhere((player) => player.hasCardsOnTable([card]));

  Player? get winner => allPlayers
    .firstWhereOrNull((p) => p.isWinner);

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
    House() => player.stacks.any((s) => s.isSet && s.house == null),
    Hotel() => player.stacks.any((s) => s.isSet && s.house != null && s.hotel == null),
    JustSayNo() => false,
    DoubleTheRent() => false,
    Stackable() => false,  // covered in previous cases
    RentActionCard(:final color1, :final color2) => othersHaveMoney
      && (player.rentFor(color1) > 0 || player.rentFor(color2) > 0),
    RainbowRentActionCard() => player.hasAProperty,
  };
}
