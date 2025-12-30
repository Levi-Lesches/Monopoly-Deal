import "package:collection/collection.dart";

import "card.dart";
import "utils.dart";
import "player.dart";

class PropertyStack {
  final PropertyColor color;
  final List<Card> cards;
  Card? house;
  Card? hotel;

  PropertyStack(this.color) : cards = [];

  bool get isSet => cards.length == color.setNumber;
  bool get hasRoom => cards.length < color.setNumber;
  bool get isEmpty => cards.isEmpty;
  bool get isNotEmpty => cards.isNotEmpty;

  bool canAdd(Card card) => switch (card) {
    PropertyCard(:final color) => color == this.color && hasRoom,
    WildPropertyCard(:final topColor, :final bottomColor) => hasRoom && color == topColor || color == bottomColor,
    RainbowWildCard() => hasRoom && isNotEmpty,
    House() => isSet,
    Hotel() => isSet && cards.any((other) => other is House),
    _ => false,
  };

  void add(Card card) => switch (card) {
    PropertyCard() || WildPropertyCard() || RainbowWildCard() => cards.add(card),
    House() => house = card,
    Hotel() => hotel = card,
    _ => { },
  };

  int get rent {
    var result = color.rents[cards.length];
    if (house != null) result += 3;
    if (hotel != null) result += 4;
    return result;
  }

  bool remove(Player player, Card card) {
    final wasSet = isSet;
    if (!cards.remove(card)) return false;
    if (wasSet && !isSet) {  // Set was broken
      final oldHouse = house;
      if (oldHouse != null) {
        player.tableMoney.add(oldHouse);
        house = null;
      }
      final oldHotel = hotel;
      if (oldHotel != null) {
        player.tableMoney.add(oldHotel);
        hotel = null;
      }
      final otherStack = player.stacks.exceptFor(this).firstWhereOrNull((other) => other.color == color);
      if (otherStack != null && !otherStack.isSet) {
        // Consolidate stacks
        final topCard = otherStack.cards.last;
        otherStack.remove(player, topCard);
        if (otherStack.isEmpty) player.stacks.remove(otherStack);
        cards.add(topCard);
      }
    }
    return true;
  }
}
