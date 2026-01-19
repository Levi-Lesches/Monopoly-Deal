import "package:meta/meta.dart";
import "package:shared/data.dart";
import "package:shared/utils.dart";

import "interruption.dart";

sealed class GameEvent {
  final String type;
  const GameEvent(this.type);

  factory GameEvent.fromJson(Json json) => switch(json["type"]) {
    "simple" => SimpleEvent.fromJson(json),
    "deal" => DealEvent.fromJson(json),
    "steal" => StealEvent.fromJson(json),
    "steal_set" => StealStackEvent.fromJson(json),
    "bank" => BankEvent.fromJson(json),
    "action" => ActionCardEvent.fromJson(json),
    "property" => PropertyEvent.fromJson(json),
    "payment" => PropertyEvent.fromJson(json),
    "discard" => PropertyEvent.fromJson(json),
    "no" => JustSayNoEvent.fromJson(json),
    _ => throw ArgumentError("Unrecognized event: $json"),
  };

  @override
  @mustBeOverridden
  String toString();

  @mustBeOverridden
  @mustCallSuper
  Json toJson() => {
    "type": type,
  };
}

class SimpleEvent extends GameEvent {
  final String message;
  const SimpleEvent(this.message) : super("simple");

  factory SimpleEvent.fromJson(Json json) => SimpleEvent(json["message"]);

  @override
  Json toJson() => {
    ...super.toJson(),
    "message": message,
  };

  @override
  String toString() => message;
}

class DealEvent extends GameEvent {
  final int amount;
  final String player;

  const DealEvent({
    required this.amount,
    required this.player,
  }) : super("deal");

  factory DealEvent.fromJson(Json json) => DealEvent(
    amount: json["amount"],
    player: json["player"],
  );

  @override
  Json toJson() => {
    ...super.toJson(),
    "amount": amount,
    "player": player,
  };

  @override
  String toString() => "Dealt $amount cards to $player";
}

class StealEvent extends GameEvent {
  final StealInterruption details;

  StealEvent(this.details) : super("steal");

  factory StealEvent.fromJson(Json json) => StealEvent(
    StealInterruption.fromJson(json["details"]),
  );

  @override
  Json toJson() => {
    ...super.toJson(),
    "details": details.toJson(),
  };

  @override
  String toString() =>
    "${details.causedBy} stole ${details.toStealName} from ${details.waitingFor}!";
}

class StealStackEvent extends GameEvent {
  StealStackInterruption details;

  StealStackEvent(this.details) : super("steal_set");

  factory StealStackEvent.fromJson(Json json) =>
    StealStackEvent(StealStackInterruption.fromJson(json["details"]));

  @override
  Json toJson() => {
    ...super.toJson(),
    "details": details.toJson(),
  };

  @override
  String toString() => "${details.causedBy} stole the ${details.color} set from ${details.waitingFor}!";
}

class BankEvent extends GameEvent {
  final String player;
  final String card;
  final bool wasAlreadyMoney;
  final int value;

  BankEvent(Player player, MCard card) :
    player = player.name,
    card = card.name,
    wasAlreadyMoney = card is MoneyCard,
    value = card.value,
    super("bank");

  BankEvent.fromJson(Json json) :
    player = json["player"],
    card = json["card"],
    wasAlreadyMoney = json["wasAlreadyMoney"],
    value = json["value"],
    super("bank");

  @override
  Json toJson() => {
    ...super.toJson(),
    "player": player,
    "card": card,
    "wasAlreadyMoney": wasAlreadyMoney,
    "value": value,
  };

  @override
  String toString() => wasAlreadyMoney
    ? "$player added $card to their bank"
    : "$player banked a(n) $card for \$$value";
}

class ActionCardEvent extends GameEvent {
  final String player;
  final int amount;
  final MCard card;
  final String? victim;
  final PropertyColor? color;
  final bool doubleTheRent;

  ActionCardEvent.charge({
    required Player player,
    required PaymentActionCard this.card,
    Player? victim,
  }) :
    player = player.name,
    amount = card.amountToPay,
    victim = victim?.name,
    color = null,
    doubleTheRent = false,
    super("action");

  ActionCardEvent.rent({
    required Player player,
    required Rentable this.card,
    required PropertyColor this.color,
    required DoubleTheRent? doubleTheRent,
    Player? victim,
  }) :
    player = player.name,
    amount = player.rentFor(color),
    victim = victim?.name,
    doubleTheRent = doubleTheRent != null,
    super("action");

  ActionCardEvent.fromJson(Json json) :
    card = cardFromJson(json["card"]),
    player = json["player"],
    amount = json["amount"],
    victim = json["victim"],
    color = json.mapNullable("color", PropertyColor.fromJson),
    doubleTheRent = json["doubleTheRent"],
    super("action");

  @override
  Json toJson() => {
    ...super.toJson(),
    "card": card.toJson(),
    "player": player,
    "amount": amount,
    "victim": victim,
    "color": color?.toJson(),
    "doubleTheRent": doubleTheRent,
  };

  @override
  String toString() {
    final buffer = StringBuffer();
    if (color == null) {
      buffer.write("$player played ${card.name} ");
      if (victim != null) buffer.write("against $victim");
      buffer.write("for \$$amount");
    } else {
      buffer.write("$player is charging rent for $color ");
      if (victim != null) buffer.write("against $victim");
      buffer.write("for the $color set (\$$amount)");
    }
    return buffer.toString();
  }
}

class PropertyEvent extends GameEvent {
  final String player;
  final String card;
  final PropertyColor color;
  final bool isModifier;

  PropertyEvent({
    required Player player,
    required this.color,
    required Stackable card,
  }) :
    card = card.name,
    player = player.name,
    isModifier = card is PropertySetModifier,
    super("property");

  PropertyEvent.fromJson(Json json) :
    player = json["player"],
    color = PropertyColor.fromJson(json["color"]),
    isModifier = json["isModifier"],
    card = json["card"],
    super("property");

  @override
  Json toJson() => {
    ...super.toJson(),
    "player": player,
    "color": color.toJson(),
    "isModifier": isModifier,
    "card": card,
  };

  @override
  String toString() => isModifier
    ? "$player built a $card on their $color set"
    : "$player placed $card as a $color property";
}

class PaymentEvent extends GameEvent {
  final List<MCard> cards;
  final int amount;
  final String from;
  final String to;

  PaymentEvent({
    required Player from,
    required Player to,
    required this.cards,
  }) :
    from = from.name,
    to = to.name,
    amount = cards.totalValue,
    super("payment");

  PaymentEvent.fromJson(Json json) :
    from = json["from"],
    to = json["to"],
    amount = json["amount"],
    cards = json.parseList("cards", cardFromJson),
    super("payment");

  @override
  Json toJson() => {
    ...super.toJson(),
    "from": from,
    "to": to,
    "amount": amount,
    "cards": [
      for (final card in cards)
        card.toJson(),
    ],
  };

  @override
  String toString() => "$from paid \$$amount to $to: $cards";
}

class DiscardEvent extends GameEvent {
  final List<MCard> cards;
  final String player;

  DiscardEvent(this.player, this.cards) : super("discard");

  DiscardEvent.fromJson(Json json) :
    player = json["player"],
    cards = json.parseList("cards", cardFromJson),
    super("discard");

  @override
  Json toJson() => {
    ...super.toJson(),
    "player": player,
    "cards": [for (final card in cards) card.toJson() ],
  };

  @override
  String toString() => "$player discarded: $cards";
}

class JustSayNoEvent extends GameEvent {
  final String player;
  const JustSayNoEvent(this.player) : super("no");

  JustSayNoEvent.fromJson(Json json) :
    player = json["player"],
    super("no");

  @override
  Json toJson() => {
    ...super.toJson(),
    "player": player,
  };

  @override
  String toString() => "$player used a Just Say No!";
}
