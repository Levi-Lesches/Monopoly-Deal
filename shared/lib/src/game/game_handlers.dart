import "package:collection/collection.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "game.dart";
import "action.dart";
import "response.dart";
import "interruption.dart";

extension GameHandlers on Game {
  void handleResponse(InterruptionResponse response) {
    final interruption = interruptions.firstWhereOrNull((other) => other.waitingFor == response.player.name);
    if (interruption == null) throw GameError.wrongResponse;
    final causedBy = findPlayer(interruption.causedBy);
    final waitingFor = findPlayer(interruption.waitingFor);
    switch (response) {
      case JustSayNoResponse(:final justSayNo):
        response.validate();
        discard(response.player, justSayNo);
      case PaymentResponse():
        if (interruption is! PaymentInterruption) throw GameError.wrongResponse;
        response.validate(interruption.amount);
        response.handle(this, causedBy);
      case AcceptedResponse():  // do the thing
        switch (interruption) {
          case StealInterruption():
            steal(interruption);
          case StealStackInterruption(:final color):
            final stack = waitingFor.getStackWithSet(color)!;
            waitingFor.stacks.remove(stack);
            causedBy.stacks.add(stack);
          case _: throw GameError.wrongResponse;
        }
      case ColorResponse(:final color):
        if (interruption is! ChooseColorInterruption) throw GameError.wrongResponse;
        final card = findCard(interruption.card) as WildCard;
        response.validate(card);
        response.player.addProperty(card, color);
      case DiscardResponse(:final cards):
        if (interruption is! DiscardInterruption) throw GameError.wrongResponse;
        response.validate(interruption.amount);
        for (final card in cards) {
          discard(currentPlayer, card);
        }
        playerIndex = players.nextIndex(playerIndex);
        startTurn();
    }
    interruptions.remove(interruption);
    if (
      interruptions.isEmpty
      && turnsRemaining == 0
      && interruption is! DiscardInterruption
    ) {
      endTurn();
    }
  }

  void handleAction(PlayerAction action) {
    if (interruptions.isNotEmpty) throw GameError("Respond to all interruptions before playing a card");
    if (turnsRemaining < action.cardsUsed) throw GameError("Too many cards played");
    action.prehandle(this);
    action.handle(this);
    action.postHandle(this);
    turnsRemaining -= action.cardsUsed;
    if (interruptions.isEmpty && turnsRemaining == 0) endTurn();
  }
}
