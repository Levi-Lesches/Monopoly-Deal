import "package:meta/meta.dart";
import "package:uuid/uuid.dart";

mixin Stackable on Card { }
// sealed class Stackable extends Card {
//   Stackable({required super.value});
// }

mixin PropertyLike on Card implements Stackable { }
mixin WildCard on Card implements PropertyLike { }
mixin PropertySetModifier on Card implements Stackable { }
// mixin Rentable on Card { }
sealed class Rentable extends Card {
  Rentable({required super.value});
}

@immutable
sealed class Card {
  String get name;
  final int value;
  final String uuid;

  Card({required this.value}) :
    uuid = const Uuid().v4();

  @override
  bool operator ==(Object other) => other is Card
    && uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() => name;
}

class MoneyCard extends Card {
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

  @override
  String toString() => name;

  int get setNumber => rents.length;
}

class PropertyCard extends Card with Stackable, PropertyLike {
  @override
  final String name;
  final PropertyColor color;

  PropertyCard({
    required this.name,
    required this.color,
    int? value,
  }) : super(value: value ?? color.value);
}

class WildPropertyCard extends Card with WildCard {
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

class RainbowWildCard extends Card with WildCard {
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

class PaymentActionCard extends Card {
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

class StealingActionCard extends Card {
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

class PassGo extends Card {
  @override
  String get name => "Pass Go";

  PassGo() : super(value: 1);
}

class House extends Card with Stackable, PropertySetModifier {
  @override
  String get name => "House";

  House() : super(value: 3);
}

class Hotel extends Card with Stackable, PropertySetModifier {
  @override
  String get name => "Hotel";

  Hotel() : super(value: 4);
}

class JustSayNo extends Card {
  @override
  String get name => "Just Say No";

  JustSayNo() : super(value: 4);
}

class DoubleTheRent extends Card {
  @override
  String get name => "Double the Rent";

  DoubleTheRent() : super(value: 1);
}

enum VictimType {
  onePlayer,
  allPlayers,
}
