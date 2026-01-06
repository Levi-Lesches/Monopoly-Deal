// Players are considered equal if they share a name
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import "package:collection/collection.dart";
import "package:meta/meta.dart";
import "package:shared/utils.dart";

import "card.dart";
import "deck.dart";
import "stack.dart";

abstract class Player {
  final String name;
  final List<PropertyStack> stacks;
  final Deck tableMoney;
  const Player({
    required this.name,
    required this.stacks,
    required this.tableMoney,
  });

  Player.fromJson(Json json) :
    name = json["name"],
    stacks = json.parseList("stacks", PropertyStack.fromJson),
    tableMoney = json.parseList("money", cardFromJson);

  int get handCount;

  @mustCallSuper
  @mustBeOverridden
  Json toJson() => {
    "name": name,
    "stacks": [
      for (final stack in stacks)
        stack.toJson(),
    ],
    "money": [
      for (final card in tableMoney)
        card.toJson(),
    ],
  };

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is Player
    && name == other.name;

  @override
  int get hashCode => name.hashCode;

  int get netWorth => _onTable.totalValue;
  bool get hasMoney => netWorth > 0;

  Deck get _onTable => [
    ...tableMoney,
    for (final stack in stacks) ...stack.cards,
  ];

  bool get hasAProperty => stacks
    .any((stack) => stack.isNotEmpty);

  bool get hasSet => stacks
    .any((stack) => stack.isSet);

  bool get hasPropertyToSteal => stacks
    .any((stack) => stack.isNotEmpty && !stack.isSet);

  Iterable<MCard> get cardsWithValue =>
    _onTable.where((card) => card.value > 0);

  PropertyStack? getStackWithSet(PropertyColor color) => stacks
    .firstWhereOrNull((stack) => stack.color == color && stack.isSet);

  PropertyStack? getStackWithRoom(PropertyColor color) => stacks
    .firstWhereOrNull((stack) => stack.color == color && stack.hasRoom);

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

  void addMoney(MCard card) => switch (card) {
    PropertyCard(:final color) => addProperty(card, color),
    _ => tableMoney.add(card),
  };

  bool hasCardsOnTable(List<MCard> cards) =>
    cards.every(_onTable.contains);

  void removeFromTable(MCard card) {
    for (final stack in stacks) {
      if (stack.remove(this, card)) return;
    }
    tableMoney.remove(card);
  }

  int rentFor(PropertyColor color) => stacks
    .where((stack) => stack.color == color)
    .map((stack) => stack.rent)
    .maxOrNull ?? 0;
}

class HiddenPlayer extends Player {
  @override
  final int handCount;

  HiddenPlayer({
    required this.handCount,
    required super.name,
    required super.stacks,
    required super.tableMoney,
  });

  HiddenPlayer.fromJson(super.json) :
    handCount = json["handCount"],
    super.fromJson();

  @override
  Json toJson() => {
    ...super.toJson(),
    "handCount": handCount,
  };
}

class RevealedPlayer extends Player {
  final Deck hand;

  RevealedPlayer(String name) : hand = [], super(
    name: name,
    tableMoney: [],
    stacks: [
      for (final color in PropertyColor.values)
        PropertyStack(color),
    ],
  );

  RevealedPlayer.fromJson(super.json) :
    hand = json.parseList("hand", cardFromJson),
    super.fromJson();

  @override
  int get handCount => hand.length;

  @override
  Json toJson() => {
    ...super.toJson(),
    "hand": [
      for (final card in hand)
        card.toJson(),
    ],
  };

  HiddenPlayer get hidden => HiddenPlayer(
    name: name,
    handCount: hand.length,
    stacks: stacks,
    tableMoney: tableMoney,
  );

  void dealCard(MCard cards) => hand.add(cards);

  bool hasCardsInHand(List<MCard> cards) =>
    cards.every(hand.contains);
}
