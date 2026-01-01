import "package:shared/utils.dart";

sealed class MDealError implements Exception {
  final String message;
  const MDealError(this.message);

  @override
  String toString() => message;

  Json toJson() => {
    "type": "error",
    "isInternal": this is GameError,
    "message": message,
  };

  factory MDealError.fromJson(Json json) => (json["isInternal"] as bool)
    ? GameError(json["message"]) : PlayerException.fromJson(json["message"]);
}

class GameError extends MDealError {
  // Represents an internal error in game flow.
  // Is an error -- cannot be fixed without code change
  GameError(super.message);

  static final interruptions = GameError("Resolve interruptions first");
  static final wrongResponse = GameError("There is no interruption for that response");
  static final notInHand = GameError("Player doesn't have that card in their hand");
  static final notOnTable = GameError("Player doesn't have that card on the table");
  static final wrongPassword = GameError("Invalid password");
}

enum PlayerExceptionReason {
  noCardToSteal("Pick a card to steal"),
  noCardToGive("Pick a card to give"),
  noColor("Pick a color"),
  noStack("No properties of that color"),
  noSet("No set of that color"),
  noRent("No rent for that color"),
  noVictim("Pick a player"),
  noValue("That card has no value"),
  noMoney("That player has no money"),
  invalidColor("Can't pick that color"),
  duplicateCardInStack("This stack already has one of those"),
  hotelBeforeHouse("Can't put a hotel before a house"),
  notEnoughMoney("Not enough money"),
  tooManyCards("Discard more cards");

  final String message;
  const PlayerExceptionReason(this.message);
}

class PlayerException extends MDealError {
  // Represents a problem with a human choice
  // Is an exception -- can be fixed by choosing something else
  PlayerException(PlayerExceptionReason reason) :
    super(reason.message);

  PlayerException.fromJson(super.message);
}
