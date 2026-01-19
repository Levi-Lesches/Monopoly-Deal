// This file uses a trick to avoid a bunch of copyWith() calls
// The UUID is modifiable *until* the game starts. Once it does,
// the whole object can be treated as immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import "package:shared/utils.dart";
import "package:uuid/uuid.dart";

extension type CardUuid.fromJson(String value) {
  CardUuid() : value = const Uuid().v4();
}

mixin Stackable on MCard { }
mixin PropertyLike on MCard implements Stackable { }
mixin WildCard on MCard implements PropertyLike { }
mixin PropertySetModifier on MCard implements Stackable { }
sealed class Rentable extends MCard {
  Rentable({required super.value});
}

sealed class MCard {
  String get name;
  final int value;
  CardUuid uuid;

  MCard({required this.value}) :
    uuid = CardUuid();

  @override
  bool operator ==(Object other) => other is MCard
    && uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() => name;

  Json toJson() => {
    "name": name,
    "uuid": uuid,
  };

  String get filename => name
    .replaceAll("(", "")
    .replaceAll(")", "")
    .replaceAll(r"$", "")
    .replaceAll("/", "");
}

class MoneyCard extends MCard {
  @override
  String get name => "\$$value";

  MoneyCard({required super.value});
}

enum PropertyColor {
  brown(rents: [1, 2], value: 1),
  lightBlue(rents: [1, 2, 3], value: 1),
  pink(rents: [1, 2, 4], value: 2),
  orange(rents: [1, 3, 5], value: 2),
  red(rents: [2, 3, 6], value: 3),
  yellow(rents: [2, 4, 6], value: 3),
  green(rents: [2, 4, 7], value: 4),
  darkBlue(rents: [3, 8], value: 4),

  railroads(rents: [1, 2, 3, 4], value: 2, isNormal: false),
  utilities(rents: [1, 2], value: 2, isNormal: false);

  final List<int> rents;
  final int value;
  final bool isNormal;  // house + hotel
  const PropertyColor({
    required this.rents,
    required this.value,
    this.isNormal = true,
  });

  String toJson() => name;

  factory PropertyColor.fromJson(String name) => values.byName(name);

  @override
  String toString() => name;

  int get setNumber => rents.length;
}

class PropertyCard extends MCard with Stackable, PropertyLike {
  @override
  final String name;
  final PropertyColor color;

  PropertyCard({
    required this.name,
    required this.color,
    int? value,
  }) : super(value: value ?? color.value);
}

class WildPropertyCard extends MCard with WildCard {
  final PropertyColor topColor;
  final PropertyColor bottomColor;

  WildPropertyCard({
    required this.topColor,
    required this.bottomColor,
    required super.value,
  });

  @override
  String get name => "Wild Property ($topColor / $bottomColor)";
}

class RainbowWildCard extends MCard with WildCard {
  RainbowWildCard() : super(value: 0);

  @override
  String get name => "Rainbow Wild Card";
}

class RentActionCard extends Rentable {
  final PropertyColor color1;
  final PropertyColor color2;

  RentActionCard({
    required this.color1,
    required this.color2,
  }) : super(value: 1);

  @override
  String get name => "Rent Card ($color1 / $color2)";
}

class RainbowRentActionCard extends Rentable {
  RainbowRentActionCard() : super(value: 3);

  @override
  String get name => "Rainbow Rent Card";
}

class PaymentActionCard extends MCard {
  // Eg, birthday, debt collector
  @override
  final String name;
  final int amountToPay;
  final VictimType victimType;

  PaymentActionCard({
    required this.amountToPay,
    required this.name,
    required this.victimType,
    required super.value,
  });
}

class StealingActionCard extends MCard {
  @override
  final String name;
  final bool canChooseSet;
  final bool isTrade;

  StealingActionCard({
    required this.name,
    required this.canChooseSet,
    required this.isTrade,
    required super.value,
  });
}

class PassGo extends MCard {
  @override
  String get name => "Pass Go";

  PassGo() : super(value: 1);
}

class House extends MCard with Stackable, PropertySetModifier {
  @override
  String get name => "House";

  House() : super(value: 3);
}

class Hotel extends MCard with Stackable, PropertySetModifier {
  @override
  String get name => "Hotel";

  Hotel() : super(value: 4);
}

class JustSayNo extends MCard {
  @override
  String get name => "Just Say No";

  JustSayNo() : super(value: 4);
}

class DoubleTheRent extends MCard {
  @override
  String get name => "Double the Rent";

  DoubleTheRent() : super(value: 1);
}

enum VictimType {
  onePlayer,
  allPlayers,
}
