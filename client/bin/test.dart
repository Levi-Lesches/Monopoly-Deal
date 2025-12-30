import "dart:io";

import "package:mdeal/data.dart";

void main() {
  final player1 = Player("Levi");
  final player2 = Player("David");
  final game = Game([player1, player2]);

  while (game.currentPlayer == player1) {
    game.printState();
    stdout.write("Choose a card [0-${player1.hand.length - 1}]: ");
    final index = int.parse(stdin.readLineSync()!);
    final card = player1.hand[index];
    final choice = TurnChoice(
      card: card,
      player: player1,
      victim: player2,
    );
    try {
      game.playCard(choice);
      game.nextCard(choice);
    } on GameError catch (e) {
      stdout.writeln("Internal error: $e");
    } on PlayerException catch (e) {
      stdout.writeln("Invalid choice: ${e.reason}");
    }
  }
  game.printState();
}
