import "game.dart";
import "response.dart";

abstract class Server {
  Stream<Response> get responses;
  Future<void> broadcastGame(Game game);
}
