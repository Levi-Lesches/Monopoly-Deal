import "package:collection/collection.dart";
import "package:shared/utils.dart";

import "card.dart";
import "errors.dart";
import "player.dart";

class PropertyStack {
  final PropertyColor color;
  final List<PropertyLike> cards;
  House? house;
  Hotel? hotel;

  PropertyStack(this.color) : cards = [];

  Json toJson() => {
    "color": color.name,
    "cards": [
      for (final card in cards)
        card.toJson(),
    ],
    "house": house?.toJson(),
    "hotel": hotel?.toJson(),
  };

  bool get isSet => cards.length == color.setNumber;
  bool get hasRoom => cards.length < color.setNumber;
  bool get isEmpty => cards.isEmpty;
  bool get isNotEmpty => cards.isNotEmpty;

  void add(Stackable card) {
    // Errors are thrown here when the game should choose a different stack
    // Exceptions are thrown otherwise
    switch (card) {
      case PropertyCard(:final color):
        if (color != this.color) throw GameError("Property color doesn't match the stack");
        if (!hasRoom) throw GameError("This stack is full");
        cards.add(card);
      case WildPropertyCard(:final topColor, :final bottomColor):
        if (color != topColor && color != bottomColor) throw GameError("Wild property colors don't match the stack");
        if (!hasRoom) throw GameError("This stack is full");
        cards.add(card);
      case RainbowWildCard():
        if (!hasRoom) throw GameError("This stack is full");
        if (isEmpty) throw GameError("Rainbow wild cards must be part of an existing stack");
        cards.add(card);
      case House():
        if (!isSet) throw GameError("This stack is not a set");
        if (house != null) throw PlayerException(.duplicateCardInStack);
        house = card;
      case Hotel():
        if (!isSet) throw GameError("This stack is not a set");
        if (house == null) throw PlayerException(.hotelBeforeHouse);
        if (hotel == null) throw PlayerException(.duplicateCardInStack);
        hotel = card;
      // case _:
    }
  }

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
