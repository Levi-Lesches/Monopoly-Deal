// In this file, the super parameters are explicitly passed to the super constructors
// ignore_for_file: use_super_parameters

import "package:meta/meta.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

sealed class Interruption {
  final String causedBy;
  final String waitingFor;

  Interruption({
    required Player causedBy,
    required Player waitingFor,
  }) : causedBy = causedBy.name, waitingFor = waitingFor.name;

  factory Interruption.parse(Json json) => switch(json["type"]) {
    "payment" => PaymentInterruption.fromJson(json),
    "stealOne" => StealInterruption.fromJson(json),
    "stealStack" => StealStackInterruption.fromJson(json),
    "color" => ChooseColorInterruption.fromJson(json),
    "discard" => DiscardInterruption.fromJson(json),
    _ => throw ArgumentError("Unrecognized interruption: $json"),
  };

  Interruption.fromJson(Json json) :
    causedBy = json["causedBy"],
    waitingFor = json["waitingFor"];

  @mustBeOverridden
  @mustCallSuper
  Json toJson() => {
    "causedBy": causedBy,
    "waitingFor": waitingFor,
  };

  @mustBeOverridden
  @override
  String toString();
}

class PaymentInterruption extends Interruption {
  final int amount;

  PaymentInterruption({
    required this.amount,
    required super.waitingFor,
    required super.causedBy,
  });

  PaymentInterruption.fromJson(Json json) :
    amount = json["amount"],
    super.fromJson(json);

  @override
  String toString() => "Waiting: $waitingFor must pay $causedBy \$$amount";

  @override
  Json toJson() => {
    ...super.toJson(),
    "type": "payment",
    "amount": amount,
  };
}

class StealInterruption extends Interruption {
  // UUIDs of cards instead of the card objects themselves
  final String toSteal;
  final String? toGive;

  final String toStealName;
  final String? toGiveName;

  StealInterruption({
    required PropertyLike toSteal,
    required PropertyLike? toGive,
    required super.waitingFor,
    required super.causedBy,
  }) :
    toSteal = toSteal.uuid,
    toStealName = toSteal.name,
    toGive = toGive?.uuid,
    toGiveName = toGive?.name;

  StealInterruption.fromJson(Json json) :
    toSteal = json["toSteal"],
    toGive = json["toGive"],
    toStealName = json["toStealName"],
    toGiveName = json["toGiveName"],
    super.fromJson(json);

  @override
  String toString() => toGive == null
    ? "Waiting: $causedBy wants to steal $toStealName from $waitingFor"
    : "Waiting: $causedBy wants to trade with $waitingFor -- $toGiveName for $toStealName";

  @override
  Json toJson() => {
    ...super.toJson(),
    "type": "stealOne",
    "toSteal": toSteal,
    "toGive": toGive,
    "toStealName": toStealName,
    "toGiveName": toGiveName,
  };
}

class StealStackInterruption extends Interruption {
  final PropertyColor color;

  StealStackInterruption({
    required this.color,
    required super.waitingFor,
    required super.causedBy,
  });

  StealStackInterruption.fromJson(Json json) :
    color = PropertyColor.fromJson(json["color"]),
    super.fromJson(json);

  @override
  String toString() => "Waiting: $causedBy wants to steal the $color set from $waitingFor";

  @override
  Json toJson() => {
    ...super.toJson(),
    "type": "stealStack",
    "color": color.name,
  };
}

class ChooseColorInterruption extends Interruption {
  final String card;  // uuid
  final List<PropertyColor> colors;
  ChooseColorInterruption({
    required WildCard card,
    required this.colors,
    required super.causedBy,
  }) : card = card.uuid, super(waitingFor: causedBy);

  ChooseColorInterruption.fromJson(Json json) :
    card = json["card"],
    colors = [
      for (final color in (json["colors"] as List).cast<String>())
        PropertyColor.fromJson(color),
    ],
    super.fromJson(json);

  @override
  Json toJson() => {
    ...super.toJson(),
    "type": "color",
    "card": card,
    "colors": colors,
  };

  @override
  String toString() => "Waiting for $waitingFor to choose a color";
}

class DiscardInterruption extends Interruption {
  final int amount;
  DiscardInterruption({
    required this.amount,
    required super.waitingFor,
  }) : super(causedBy: waitingFor);

  DiscardInterruption.fromJson(Json json) :
    amount = json["amount"],
    super.fromJson(json);

  @override
  Json toJson() => {
    "type": "discard",
    ...super.toJson(),
    "amount": amount,
  };

  @override
  String toString() => "Waiting for $waitingFor to discard at least $amount cards";
}
