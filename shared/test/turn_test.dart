import "package:test/test.dart";
import "package:shared/shared.dart";

void main() => test("One full turn", () {
  final alice = RevealedPlayer("Alice");
  final bob = RevealedPlayer("Bob");
  final game = Game([alice, bob]);

  // Check the game was set up normally
  expect(game.interruptions, isEmpty);
  expect(game.currentPlayer, alice);
  expect(game.turnsRemaining, 3);
  expect(alice.hand.length, 7);
  expect(bob.hand.length, 5);

  // Add money to Bob's bank account -- this can only be done by the server
  final money2 = MoneyCard(value: 2);
  final money3 = MoneyCard(value: 3);
  expect(bob.netWorth, 0);
  bob.addMoney(money2);
  bob.addMoney(money3);
  expect(bob.netWorth, 5);

  // Make a debt collector against Bob
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

  // The game now has one interruption: Bob must pay $5
  expect(game.interruptions.length, 1);
  final interruption = game.interruptions.first;
  expect(interruption, isA<PaymentInterruption>());
  if (interruption is! PaymentInterruption) return;
  expect(interruption.waitingFor, bob.name);
  expect(interruption.amount, 5);

  // Try to make up fake money for Bob
  final extraMoney = MoneyCard(value: 5);
  final wrongResponse = PaymentResponse(cards: [extraMoney], player: bob);
  game.checkBadResponse(wrongResponse);

  // Caught! Use the money Bob actually has
  final goodResponse = PaymentResponse(cards: [money2, money3], player: bob);
  game.checkResponse(goodResponse);
  expect(bob.netWorth, 0);
  expect(game.interruptions, isEmpty);

  // Alice's turn, 2nd card: It's my Birthday!
  final birthday = itsMyBirthday();
  alice.hand.add(birthday);
  expect(alice.hand.length, 8);
  final birthdayAction = ChargeAction(card: birthday, player: alice);
  game.checkAction(birthdayAction);
  expect(alice.hand.length, 7);
  expect(game.turnsRemaining, 1);

  // This should not charge anyone because Bob has $0
  expect(game.interruptions, isEmpty);

  // Alice's turn, 3rd card: Pass Go
  final passGo = PassGo();
  alice.hand.add(passGo);
  expect(alice.hand.length, 8);
  final passGoAction = PassGoAction(card: passGo, player: alice);
  game.checkAction(passGoAction);
  expect(alice.hand.length, 9);  // 8 - 1 + 2 = 9
  expect(game.turnsRemaining, 0);

  // Alice is allowed to re-arrange her cards until she says she is done.
  expect(game.interruptions, isEmpty);
  final doneAction = EndTurnAction(player: alice);
  game.handleAction(doneAction);
  expect(game.interruptions, isNotEmpty);

  // End of Alice's turn, they need to discard 2 cards
  final discardInterruption = game.interruptions.first;
  expect(discardInterruption, isA<DiscardInterruption>());
  if (discardInterruption is! DiscardInterruption) return;
  expect(discardInterruption.amount, 2);
  expect(discardInterruption.waitingFor, alice.name);

  // Discard the first and last card in their hand
  final cards = [alice.hand.first, alice.hand.last];
  final response = DiscardResponse(cards: cards, player: alice);
  game.checkResponse(response);

  // Now there should be no more interruptions, and Bob can start
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
