import "package:collection/collection.dart";

import "card.dart";
import "deck.dart";
import "stack.dart";

class Player {
  final String name;
  final Deck hand;
  final List<PropertyStack> stacks;
  final Deck tableMoney;

  Player(this.name) :
    hand = [],
    tableMoney = [],
    stacks = [
      for (final color in PropertyColor.values)
        PropertyStack(color),
    ];

  @override
  String toString() => name;

  int get netWorth => _onTable.totalValue;

  Deck get _onTable => [
    ...tableMoney,
    for (final stack in stacks) ...stack.cards,
  ];

  Iterable<Card> get cardsWithValue =>
    _onTable.where((card) => card.value > 0);

  void dealCard(Card cards) => hand.add(cards);

  PropertyStack? getStackWithSet(PropertyColor color) => stacks
    .firstWhereOrNull((stack) => stack.color == color && stack.isSet);

  PropertyStack? getStackWithRoom(PropertyColor color) => stacks
    .firstWhereOrNull((stack) => stack.color == color && stack.hasRoom);

  int rentFor(PropertyColor color) => stacks
    .where((stack) => stack.color == color)
    .map((stack) => stack.rent)
    .max;

  bool hasCardsOnTable(List<Card> cards) =>
    cards.every(_onTable.contains);

  bool hasCardsInHand(List<Card> cards) =>
    cards.every(hand.contains);

  void removeFromTable(Card card) {
    for (final stack in stacks) {
      if (stack.remove(this, card)) return;
    }
    tableMoney.remove(card);
  }

  void addProperty(Stackable card, PropertyColor color) {
    final stack = getStackWithRoom(color);
    if (stack == null) {
      final newStack = PropertyStack(color);
      newStack.add(card);
      stacks.add(newStack);
    } else {
      stack.add(card);
    }
  }

  void addMoney(Card card) => switch (card) {
    PropertyCard(:final color) => addProperty(card, color),
    _ => tableMoney.add(card),
  };
}
