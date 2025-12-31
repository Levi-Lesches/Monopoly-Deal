import "package:collection/collection.dart";
import "package:shared/shared.dart";
import "package:test/test.dart";

void main() => test("Card JSON", () {
  final deck = shuffleDeck();
  final deckJson = [
    for (final card in deck)
      card.toJson(),
  ];
  final deck2 = [
    for (final cardJson in deckJson)
      cardfromJson(cardJson),
  ];
  expect(deck.length, 106);
  expect(deck2.length, 106);
  for (final [card1, card2] in IterableZip([deck, deck2])) {
    expect(card1, card2);
  }
});
