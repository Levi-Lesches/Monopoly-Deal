import "package:shared/data.dart";

sealed class Interruption {
  final Player causedBy;
  final Player waitingFor;

  const Interruption({
    required this.causedBy,
    required this.waitingFor,
  });
}

class PaymentInterruption extends Interruption {
  final int amount;

  const PaymentInterruption({
    required this.amount,
    required super.waitingFor,
    required super.causedBy,
  });

  @override
  String toString() => "Waiting: $waitingFor must pay $causedBy \$$amount";
}

class StealInterruption extends Interruption {
  final PropertyLike toSteal;
  final PropertyLike? toGive;

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

class StealStackInterruption extends Interruption {
  final PropertyColor color;

  const StealStackInterruption({
    required this.color,
    required super.waitingFor,
    required super.causedBy,
  });

  @override
  String toString() => "Waiting: $causedBy wants to steal the $color set from $waitingFor";
}

class ChooseColorInterruption extends Interruption {
  final WildCard card;
  const ChooseColorInterruption({
    required this.card,
    required super.causedBy,
  }) : super(waitingFor: causedBy);
}

class DiscardInterruption extends Interruption {
  final int amount;
  const DiscardInterruption({
    required this.amount,
    required super.waitingFor,
  }) : super(causedBy: waitingFor);
}
