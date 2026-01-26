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
    "justSayNo" => JustSayNoInterruption.fromJson(json),
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
  final CardUuid toStealUuid;
  final CardUuid? toGiveUuid;

  final String toStealName;
  final String? toGiveName;

  MCard get toSteal => cardFromJson({"uuid": toStealUuid, "name": toStealName});
  MCard? get toGive => toGiveName == null ? null : cardFromJson({"uuid": toGiveUuid, "name": toGiveName});

  bool get isTrade => toGiveName != null;

  StealInterruption({
    required PropertyLike toSteal,
    required PropertyLike? toGive,
    required super.waitingFor,
    required super.causedBy,
  }) :
    toStealUuid = toSteal.uuid,
    toStealName = toSteal.name,
    toGiveUuid = toGive?.uuid,
    toGiveName = toGive?.name;

  StealInterruption.fromJson(Json json) :
    toStealUuid = json["toSteal"],
    toGiveUuid = json["toGive"],
    toStealName = json["toStealName"],
    toGiveName = json["toGiveName"],
    super.fromJson(json);

  @override
  String toString() => toGiveUuid == null
    ? "$causedBy wants to steal $toStealName from $waitingFor"
    : "$causedBy wants to steal $toStealName and give $toGiveName";

  String wideString() => toGiveName == null
    ? "$causedBy\nwants to steal your\n$toStealName"
    : "$causedBy\nwants to steal your\n$toStealName\nand give you\n $toGiveName";

  @override
  Json toJson() => {
    ...super.toJson(),
    "type": "stealOne",
    "toSteal": toStealUuid,
    "toGive": toGiveUuid,
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
  final CardUuid card;
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

class JustSayNoInterruption extends Interruption {
  Interruption original;

  JustSayNoInterruption({
    required this.original,
    required super.causedBy,
    required super.waitingFor,
  });

  JustSayNoInterruption.fromJson(Json json) :
    original = Interruption.parse(json["original"]),
    super.fromJson(json);

  @override
  Json toJson() => {
    ...super.toJson(),
    "type": "justSayNo",
    "original": original.toJson(),
  };

  @override
  String toString() => "Waiting for $waitingFor to counter a Just Say No by $causedBy";
}
