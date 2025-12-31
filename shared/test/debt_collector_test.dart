import "package:test/test.dart";
import "package:shared/shared.dart";

void main() => test("Debt collector", () {
  // Alice uses a debt collector on Bob, and he pays with a $3 and $2
  final alice = Player("Alice");
  final bob = Player("Bob");
  final game = Game([alice, bob]);

  // Check the game was set up normally
  expect(game.interruptions, isEmpty);
  expect(game.currentPlayer, alice);
  expect(game.turnsRemaining, 3);
  expect(alice.hand.length, 7);
  expect(bob.hand.length, 5);

  // Add money to player 2's bank account -- this can only be done by the server
  final money2 = MoneyCard(value: 2);
  final money3 = MoneyCard(value: 3);
  expect(bob.netWorth, 0);
  bob.addMoney(money2);
  bob.addMoney(money3);
  expect(bob.netWorth, 5);

  // Make a debt collector against player 2
  final card = debtCollector();
  final action = ChargeAction(card: card, player: alice, victim: bob);

  // Trick the game by playing a card we don't have
  game.checkBadAction(action);

  // Caught! Add the card to the player's hand in order to play it
  alice.hand.add(card);
  expect(alice.hand.length, 8);
  expect(alice.hand, contains(card));
  game.checkAction(action);
  expect(alice.hand.length, 7);
  expect(game.turnsRemaining, 2);

  // The game now has one interrution: Player 2 must pay $5
  expect(game.interruptions.length, 1);
  final interruption = game.interruptions.first;
  expect(interruption, isA<PaymentInterruption>());
  if (interruption is! PaymentInterruption) return;
  expect(interruption.waitingFor, bob);
  expect(interruption.amount, 5);

  // Try to make up fake money for player 2
  final extraMoney = MoneyCard(value: 5);
  final wrongResponse = PaymentResponse(cards: [extraMoney], player: bob);
  game.checkBadResponse(wrongResponse);

  // Caught! Use the money player 2 actually has
  final goodResponse = PaymentResponse(cards: [money2, money3], player: bob);
  game.checkResponse(goodResponse);
  expect(bob.netWorth, 0);
  expect(game.interruptions, isEmpty);

  // Player 1's turn, 2nd card: It's my Birthday!
  final birthday = itsMyBirthday();
  alice.hand.add(birthday);
  expect(alice.hand.length, 8);
  final birthdayAction = ChargeAction(card: birthday, player: alice);
  game.checkAction(birthdayAction);
  expect(alice.hand.length, 7);
  expect(game.turnsRemaining, 1);

  // This should not charge anyone because Player 2 has $0
  expect(game.interruptions, isEmpty);

  // Player 1's turn, 3rd card: Pass Go
  final passGo = PassGo();
  alice.hand.add(passGo);
  expect(alice.hand.length, 8);
  final passGoAction = PassGoAction(card: passGo, player: alice);
  game.checkAction(passGoAction);
  expect(alice.hand.length, 9);  // 8 - 1 + 2 = 9
  expect(game.turnsRemaining, 0);

  // End of Player 1's turn, they need to discard 2 cards
  expect(game.interruptions, isNotEmpty);
  final discardInterruption = game.interruptions.first;
  expect(discardInterruption, isA<DiscardInterruption>());
  if (discardInterruption is! DiscardInterruption) return;
  expect(discardInterruption.amount, 2);
  expect(discardInterruption.waitingFor, alice);

  // Discard the first and last card in their hand
  final cards = [alice.hand.first, alice.hand.last];
  final response = DiscardResponse(cards: cards, player: alice);
  game.checkResponse(response);

  // Now there should be no more interruptions, and Player 2 can start
  expect(game.interruptions, isEmpty);
  expect(game.currentPlayer, bob);
  expect(game.turnsRemaining, 3);
});

void expectError<T>(void Function() func) => expect(func, throwsA(isA<T>()));

extension on Game {
  void checkAction(PlayerAction action) => expect(() => handleAction(action), returnsNormally);
  void checkBadAction(PlayerAction action) => expectError<GameError>(() => handleAction(action));
  void checkResponse(InterruptionResponse response) => expect(() => handleResponse(response), returnsNormally);
  void checkBadResponse(InterruptionResponse response) => expectError<GameError>(() => handleResponse(response));
}
