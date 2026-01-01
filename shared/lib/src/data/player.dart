// Players are considered equal if they share a name
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import "package:collection/collection.dart";
import "package:shared/utils.dart";

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

  @override
  bool operator ==(Object other) => other is Player
    && name == other.name;

  @override
  int get hashCode => name.hashCode;

  Json toJson() => {
    "name": name,
    "handCount": hand.length,
    "stacks": [
      for (final stack in stacks)
        stack.toJson(),
    ],
    "money": [
      for (final card in tableMoney)
        card.toJson(),
    ],
  };

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
