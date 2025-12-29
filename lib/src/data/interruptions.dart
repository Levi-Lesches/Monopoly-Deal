import "player.dart";
import "card.dart";

sealed class GameInterruption {
  final Player causedBy;
  final Player waitingFor;

  const GameInterruption({
    required this.causedBy,
    required this.waitingFor,
  });
}

class PaymentInterruption extends GameInterruption {
  final int amount;

  const PaymentInterruption({
    required this.amount,
    required super.waitingFor,
    required super.causedBy,
  });

  @override
  String toString() => "Waiting: $waitingFor must pay $causedBy \$$amount";
}

class StealInterruption extends GameInterruption {
  final Card toSteal;
  final Card? toGive;

  const StealInterruption({
    required this.toSteal,
    required this.toGive,
    required super.waitingFor,
    required super.causedBy,
  });

  @override
  String toString() => toGive == null
    ? "Waiting: $causedBy wants to steal $toSteal from $waitingFor"
    : "Waiting: $causedBy wants to trade with $waitingFor -- $toGive for $toSteal";
}

class StealStackInterruption extends GameInterruption {
  final PropertyColor color;

  const StealStackInterruption({
    required this.color,
    required super.waitingFor,
    required super.causedBy,
  });

  @override
  String toString() => "Waiting: $causedBy wants to steal the $color set from $waitingFor";
}

class ChooseColorInterruption extends GameInterruption {
  final Card card;
  const ChooseColorInterruption({
    required this.card,
    required super.causedBy,
  }) : super(waitingFor: causedBy);
}
