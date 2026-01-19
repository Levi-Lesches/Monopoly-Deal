import "package:collection/collection.dart";
import "package:shared/utils.dart";

import "card.dart";
import "deck.dart";
import "errors.dart";
import "player.dart";

class PropertyStack {
  final PropertyColor color;
  final List<PropertyLike> cards;
  House? house;
  Hotel? hotel;

  List<MCard> get allCards => [...cards, ?house, ?hotel];

  PropertyStack(this.color) : cards = [];

  PropertyStack.fromJson(Json json) :
    color = PropertyColor.fromJson(json["color"]),
    cards = json.parseList("cards", (json) => cardFromJson(json) as PropertyLike),
    house = json.mapNullable("house", (Json h) => cardFromJson(h) as House),
    hotel = json.mapNullable("hotel", (Json h) => cardFromJson(h) as Hotel);

  Json toJson() => {
    "color": color.name,
    "cards": [
      for (final card in cards)
        card.toJson(),
    ],
    "house": house?.toJson(),
    "hotel": hotel?.toJson(),
  };

  @override
  String toString() => "$color stack";

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
        // Don't check for rainbow wild errors here, player might be forced to use it
        cards.add(card);
      case House():
        if (!isSet) throw GameError("This stack is not a set");
        if (house != null) throw PlayerException(.duplicateCardInStack);
        house = card;
      case Hotel():
        if (!isSet) throw GameError("This stack is not a set");
        if (house == null) throw PlayerException(.hotelBeforeHouse);
        if (hotel != null) throw PlayerException(.duplicateCardInStack);
        hotel = card;
    }
  }

  int get rent {
    if (cards.isEmpty) return 0;
    var result = color.rents[cards.length - 1];
    if (house != null) result += 3;
    if (hotel != null) result += 4;
    return result;
  }

  bool remove(Player player, MCard card) {
    final wasSet = isSet;
    if (!cards.remove(card)) return false;
    if (card is House) {
      final oldHotel = hotel;
      if (oldHotel != null) {
        player.tableMoney.add(oldHotel);
        hotel = null;
      }
    }
    if (wasSet && !isSet) {  // Set was broken
      final otherStack = player.stacks.exceptFor(this).firstWhereOrNull((other) => other.color == color && other.isNotEmpty);
      if (otherStack != null && !otherStack.isSet) {
        // Consolidate stacks
        final topCard = otherStack.cards.last;
        otherStack.remove(player, topCard);
        if (otherStack.isEmpty) player.stacks.remove(otherStack);
        cards.add(topCard);
      }
      if (!isSet) {
        // Even after consolidating, this is still not a set
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
      }
    }
    return true;
  }
}
