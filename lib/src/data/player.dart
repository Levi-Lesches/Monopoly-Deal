import "card.dart";
import "deck.dart";

class PropertyStack {
  final PropertyColor color;
  final List<Card> cards;
  Card? house;
  Card? hotel;

  PropertyStack(this.color) : cards = [];

  bool get isSet => cards.length == color.setNumber;

  bool get hasRoom => cards.length < color.setNumber;

  bool canAdd(Card card) => switch (card) {
    PropertyCard(:final color) => color == this.color && hasRoom,
    WildPropertyCard(:final topColor, :final bottomColor) => hasRoom && color == topColor || color == bottomColor,
    RainbowWildCard() => hasRoom && cards.isNotEmpty,
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
    if (!cards.remove(card)) return false;
    if (!isSet) {
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
    return true;
  }
}

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

  int get netWorth => onTable.totalValue;

  Deck get onTable => [
    ...tableMoney,
    for (final stack in stacks) ...stack.cards,
  ];

  Iterable<Card> get cardsWithValue =>
    onTable.where((card) => card.value > 0);

  void dealCard(Card cards) => hand.add(cards);

  PropertyStack getStack(PropertyColor color) =>
    stacks.firstWhere((stack) => stack.color == color);

  int rentFor(PropertyColor color) => stacks
    .firstWhere((stack) => stack.color == color)
    .rent;

  bool hasCardsOnTable(List<Card> cards) =>
    cards.every(onTable.contains);

  bool hasCardsInHand(List<Card> cards) =>
    cards.every(hand.contains);

  void removeFromTable(Card card) {
    for (final stack in stacks) {
      if (stack.remove(this, card)) return;
    }
    tableMoney.remove(card);
  }

  // TODO: Handle a 4th card being given
  void addAsMoney(Card card) => switch (card) {
    PropertyCard(:final color) || WildPropertyCard(topColor: final color) =>
      getStack(color).add(card),
    _ => tableMoney.add(card),
  };
}

/*

1. Request: Choose card. Player1
  Response: Debt Collector
  Request: Choose player. Player1
  Response: Player2
  Request: Choose payment. Player2
  Response: $5
  Turn over

2. Request: Choose card. Player1
  Response: Debt Collector, Player2
  Request: Choose payment. Player2
  Response: $5
  Turn over

3. Request for Player1: [chooseCard]
  - CardChoice(card: debtCollector, victim: player2)
  Request for Player2: [choosePayment]

4. State = player1, turnsRemaining = 3
  - Choice = (card: debtCollector, victim: player2)
  - interruption: (player: Player2, amount: 5)
  - response: (cards: [$3, $2])
*/
