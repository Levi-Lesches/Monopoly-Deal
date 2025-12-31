import "package:collection/collection.dart";
import "package:shared/utils.dart";

import "card.dart";

typedef Deck = List<Card>;

List<E> fill<E extends Card>(int n, E Function() builder) =>
  List.generate(n, (_) => builder());

Card cardfromJson(Json json) {
  final name = json["name"];
  final deck = buildDeck();
  final card = deck.firstWhere((other) => other.name == name)
    ..uuid = json["uuid"];
  deck.remove(card);
  return card;
}

Deck _buildMoneyCards() => [
  ...fill(6, () => MoneyCard(value: 1)),
  ...fill(5, () => MoneyCard(value: 2)),
  ...fill(3, () => MoneyCard(value: 3)),
  ...fill(3, () => MoneyCard(value: 4)),
  ...fill(2, () => MoneyCard(value: 5)),
  ...fill(1, () => MoneyCard(value: 10)),
];

PaymentActionCard debtCollector() => PaymentActionCard(
  amountToPay: 5,
  name: "Debt Collector",
  victimType: VictimType.onePlayer,
  value: 3,
);

Card slyDeal() => StealingActionCard(
  name: "Sly Deal",
  canChooseSet: false,
  isTrade: false,
  value: 3,
);

Card forcedDeal() => StealingActionCard(
  name: "Forced Deal",
  canChooseSet: false,
  isTrade: true,
  value: 3,
);

Card dealBreaker() => StealingActionCard(
  name: "Deal Breaker",
  canChooseSet: true,
  isTrade: false,
  value: 5,
);

PaymentActionCard itsMyBirthday() => PaymentActionCard(
  amountToPay: 2,
  name: "It's My Birthday!",
  victimType: VictimType.allPlayers,
  value: 2,
);

Deck _buildActionCards() => [
  ...fill(2, dealBreaker),
  ...fill(3, JustSayNo.new),
  ...fill(3, slyDeal),
  ...fill(3, forcedDeal),
  ...fill(3, debtCollector),
  ...fill(3, itsMyBirthday),
  ...fill(10, PassGo.new),
  ...fill(3, House.new),
  ...fill(2, Hotel.new),
  ...fill(2, DoubleTheRent.new),
];

Deck _buildPropertyCards() => [
  PropertyCard(name: "Baltic Avenue", color: .brown),
  PropertyCard(name: "Mediterranean Avenue", color: .brown),

  PropertyCard(name: "Oriental Avenue", color: .lightBlue),
  PropertyCard(name: "Vermont Avenue", color: .lightBlue),
  PropertyCard(name: "Connecticut Avenue", color: .lightBlue),

  PropertyCard(name: "St. Charles Place", color: .pink),
  PropertyCard(name: "States Avenue", color: .pink),
  PropertyCard(name: "Virginia Avenua", color: .pink),

  PropertyCard(name: "St. James Place", color: .orange),
  PropertyCard(name: "Tennessee Avenue", color: .orange),
  PropertyCard(name: "New York Avenue", color: .orange),

  PropertyCard(name: "Kentucky Avenue", color: .red),
  PropertyCard(name: "Indiana Avenue", color: .red),
  PropertyCard(name: "Illinois Avenue", color: .red),

  PropertyCard(name: "Ventnor Avenue", color: .yellow),
  PropertyCard(name: "Atlantic Avenue", color: .yellow),
  PropertyCard(name: "Marvin Gardens", color: .yellow),

  PropertyCard(name: "Pacific Avenue", color: .green),
  PropertyCard(name: "Pennsylvania Avenue", color: .green),
  PropertyCard(name: "North Carolina Avenue", color: .green),

  PropertyCard(name: "Park Place", color: .darkBlue),
  PropertyCard(name: "Boardwalk Avenue", color: .darkBlue),

  PropertyCard(name: "Reading Railroad", color: .railroads),
  PropertyCard(name: "Pennsylvania Railroad", color: .railroads),
  PropertyCard(name: "B. & O. Railroad", color: .railroads),
  PropertyCard(name: "Short Line", color: .railroads),

  PropertyCard(name: "Electric Company", color: .utilities),
  PropertyCard(name: "Water Works", color: .utilities),
];

Deck _buildWildCards() => [
  WildPropertyCard(topColor: .pink, bottomColor: .orange, value: 2),
  WildPropertyCard(topColor: .pink, bottomColor: .orange, value: 2),
  WildPropertyCard(topColor: .lightBlue, bottomColor: .brown, value: 1),
  WildPropertyCard(topColor: .darkBlue, bottomColor: .green, value: 4),
  WildPropertyCard(topColor: .railroads, bottomColor: .green, value: 4),
  WildPropertyCard(topColor: .railroads, bottomColor: .lightBlue, value: 4),
  WildPropertyCard(topColor: .red, bottomColor: .yellow, value: 3),
  WildPropertyCard(topColor: .red, bottomColor: .yellow, value: 3),
  WildPropertyCard(topColor: .railroads, bottomColor: .utilities, value: 2),
  RainbowWildCard(),
  RainbowWildCard(),
];

Deck _buildRentCards() => [
  RainbowRentActionCard(),
  RainbowRentActionCard(),
  RainbowRentActionCard(),

  RentActionCard(color1: .green, color2: .darkBlue),
  RentActionCard(color1: .green, color2: .darkBlue),

  RentActionCard(color1: .brown, color2: .lightBlue),
  RentActionCard(color1: .brown, color2: .lightBlue),

  RentActionCard(color1: .pink, color2: .orange),
  RentActionCard(color1: .pink, color2: .orange),

  RentActionCard(color1: .railroads, color2: .utilities),
  RentActionCard(color1: .railroads, color2: .utilities),

  RentActionCard(color1: .red, color2: .yellow),
  RentActionCard(color1: .red, color2: .yellow),
];

Deck buildDeck() => [
  // See: https://monopolydealrules.com/index.php?page=cards
  ..._buildActionCards(),
  ..._buildPropertyCards(),
  ..._buildWildCards(),
  ..._buildRentCards(),
  ..._buildMoneyCards(),
];

Deck shuffleDeck() => buildDeck().shuffled();

extension DeckUtils on Deck {
  int get totalValue => map((card) => card.value).sum;
}
