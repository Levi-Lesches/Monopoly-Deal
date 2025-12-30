import "package:shared/shared.dart";

abstract class Server<Client> {  // [P = identify client]
  final clients = <Client>[];
  final Game game;
  Server(this.game);

  Future<void> handleAction(Client client, PlayerAction action) async {
    try {
      game.handleAction(action);
      await broadcastToAll();
    } on MDealError catch (error) {
      await sendError(client, error);
    }
  }
  Future<void> handleResponse(Client client, InterruptionResponse response) async {
    try {
      game.handleResponse(response);
      await broadcastToAll();
    } on MDealError catch (error) {
      await sendError(client, error);
    }
  }

  Future<void> init();
  Future<void> dispose();
  Future<void> broadcastToAll() => Future.wait(clients.map(broadcastTo));
  Future<void> broadcastTo(Client client);
  Future<void> sendError(Client client, MDealError error);
}
