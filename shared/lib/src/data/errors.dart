sealed class MDealError implements Exception { }

class GameError implements MDealError {
  // Represents an internal error in game flow.
  // Is an error -- cannot be fixed without code change
  final String message;
  GameError(this.message);

  static final interruptions = GameError("Resolve interruptions first");
  static final wrongResponse = GameError("There is no interruption for that response");
  static final notInHand = GameError("Player doesn't have that card in their hand");
  static final notOnTable = GameError("Player doesn't have that card on the table");
}

enum ChoiceExceptionReason {
  noCardToSteal,
  noCardToGive,
  noColor,
  noStack,
  noSet,
  noRent,
  noVictim,
  noValue,
  noMoney,
  invalidColor,
  duplicateCardInStack,
  hotelBeforeHouse,
  notEnoughMoney,
  tooManyCards,
}

class PlayerException implements MDealError {
  // Represents a problem with a human choice
  // Is an exception -- can be fixed by choosing something else
  final ChoiceExceptionReason reason;
  PlayerException(this.reason);
}
