import "game.dart";
import "response.dart";

abstract class Server {
  Stream<Response> get responses;
  Future<void> broadcastGame(Game game);
}

/*

Option 1: Server manages the game
Debt collector example:
- Server calls game.start(), broadcasts
- Server receives Choice(debtCollector), calls game.playCard()
- Server sends game.interruptions
- [Optional] Server sends true/false to client
- Server sends game.state() to clients
-


Option 2: The game holds a server

*/
