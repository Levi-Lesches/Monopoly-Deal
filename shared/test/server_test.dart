// Like turn_test.dart, but with a server
//
// The code at this stage assumes that packets are coming from
// a legitimate client. If not, the server will just spit out errors
// without helpful messages. Since I don't plan on releasing more
// than one client, this won't change.
//
// Therefore, all the "sneaky" tests from turn_test.dart, like using
// cards the server isn't aware of, have been removed, under the
// assumption that the client I'm writing won't behave maliciously.
// These weren't generating useful results anyway, just parsing errors.
import "dart:async";

import "package:shared/shared.dart";
import "package:test/test.dart";

import "mock_sockets.dart";

void main() => test("Server test", () async {
  final aliceClient = MDealClient(MockClientSocket(aliceUser));
  await aliceClient.init();

  final bobClient = MDealClient(MockClientSocket(bobUser));
  await bobClient.init();

  aliceClient.expectUpdate();
  bobClient.expectUpdate();
  final server = Server([aliceUser, bobUser], MockServerSocket());
  await server.init();

  final game = server.game;
  final alice = game.findPlayer(aliceUser.name);
  final bob = game.findPlayer(bobUser.name);

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
  game.debugAddMoney(bob, money2);
  game.debugAddMoney(bob, money3);
  expect(bob.netWorth, 5);

  // Make a debt collector and add it to Alice's hand
  final card = debtCollector();
  game.debugAddToHand(alice, card);
  expect(alice.hand.length, 8);
  expect(alice.hand, contains(card));

  // Play the debt collector against Bob
  aliceClient.expectUpdate();
  bobClient.expectUpdate();
  final action = ChargeAction(card: card, player: alice, victim: bob);
  await aliceClient.sendAction(action);
  expect(alice.hand.length, 7);
  expect(game.turnsRemaining, 2);

  // The game now has one interruption: Bob must pay $5
  expect(game.interruptions.length, 1);
  final interruption = game.interruptions.first;
  expect(interruption, isA<PaymentInterruption>());
  if (interruption is! PaymentInterruption) return;
  expect(interruption.waitingFor, bob.name);
  expect(interruption.amount, 5);

  // Pay with Bob's money
  aliceClient.expectUpdate();
  bobClient.expectUpdate();
  final response = PaymentResponse(cards: [money2, money3], player: bob);
  await bobClient.sendResponse(response);
  expect(bob.netWorth, 0);
  expect(game.interruptions, isEmpty);

  // Alice's second card: It's my Birthday!
  final birthday = itsMyBirthday();
  game.debugAddToHand(alice, birthday);
  expect(alice.hand.length, 8);
  final birthdayAction = ChargeAction(card: birthday, player: alice);
  aliceClient.expectUpdate();
  bobClient.expectUpdate();
  await aliceClient.sendAction(birthdayAction);
  expect(alice.hand.length, 7);
  expect(game.turnsRemaining, 1);
  expect(game.interruptions, isEmpty);

  // Alice's 3rd card: Pass Go
  final passGo = PassGo();
  game.debugAddToHand(alice, passGo);
  expect(alice.hand.length, 8);
  final passGoAction = PassGoAction(card: passGo, player: alice);
  aliceClient.expectUpdate();
  bobClient.expectUpdate();
  await aliceClient.sendAction(passGoAction);
  expect(alice.hand.length, 9);  // 8 - 1 + 2 = 9
  expect(game.turnsRemaining, 0);

  // End of Alice's turn, they need to discard 2 cards
  expect(game.interruptions, isNotEmpty);
  final discardInterruption = game.interruptions.first;
  expect(discardInterruption, isA<DiscardInterruption>());
  if (discardInterruption is! DiscardInterruption) return;
  expect(discardInterruption.amount, 2);
  expect(discardInterruption.waitingFor, alice.name);

  // Discard the first and last card in their hand
  final cards = [alice.hand.first, alice.hand.last];
  final discardResponse = DiscardResponse(cards: cards, player: alice);
  aliceClient.expectUpdate();
  bobClient.expectUpdate();
  await aliceClient.sendResponse(discardResponse);

  // Now there should be no more interruptions, and Bob can start
  expect(game.interruptions, isEmpty);
  expect(game.currentPlayer, bob);
  expect(game.turnsRemaining, 3);

  // Needed so that stream events finish processing
  await Future<void>.delayed(Duration.zero);
  await aliceClient.dispose();
  await bobClient.dispose();
  await server.dispose();
  final controllers = [...clientControllers.values, ...serverControllers.values];
  for (final controller in controllers) {
    await controller.close();
  }
});

extension on MDealClient {
  void expectUpdate() => expect(gameUpdates, emits(isA<GameState>()));
}
