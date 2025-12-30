sealed class MDealError implements Exception { }

class GameError implements MDealError {
  // Represents an internal error in game flow.
  // Is an error -- cannot be fixed without code change
  final String message;
  GameError(this.message);
}

enum ChoiceExceptionReason {
  noColor,
  noStack,
  noSet,
  noRent,
  noVictim,
  noCardToSteal,
  noCardToGive,
  invalidColor,
  duplicateCardInStack,
  hotelBeforeHouse,
}

class PlayerException implements MDealError {
  // Represents a problem with a human choice
  // Is an exception -- can be fixed by choosing something else
  final ChoiceExceptionReason reason;
  PlayerException(this.reason);
}
