import "package:shared/shared.dart";

import "socket.dart";

class Server {
  final Game game;
  final MDealSocket socket;
  final List<User> users;

  Server(this.users, this.socket) :
    game = Game([for (final user in users) Player(user.name)]);

  Future<void> init() async {
    await socket.init();
    socket.listen(handlePacket);
    await broadcastToAll();
  }

  Future<void> handlePacket(User user, Packet packet) async {
    // {
    //  "type": "action" | "response",
    //  "name": ActionName | ResponseName,
    //  "data": Json,
    // }
    final type = packet["type"];
    final name = packet["name"];
    final data = packet["data"];
    switch (type) {
      case "action":
        final PlayerAction action = PlayerAction.fromJson(name, data);
        if (action.player.name != user.name) return;
        await handleAction(user, action);
      case "response":
        final InterruptionResponse response = InterruptionResponse.fromJson(name, data);
        if (response.player.name != user.name) return;
        await handleResponse(user, response);
    }
  }

  Future<void> handleAction(User user, PlayerAction action) async {
    try {
      game.handleAction(action);
      await broadcastToAll();
    } on MDealError catch (error) {
      await sendError(user, error);
    }
  }

  Future<void> handleResponse(User user, InterruptionResponse response) async {
    try {
      game.handleResponse(response);
      await broadcastToAll();
    } on MDealError catch (error) {
      await sendError(user, error);
    }
  }

  Future<void> dispose() async {
    await socket.dispose();
  }

  Future<void> broadcastToAll() =>
    Future.wait(users.map(broadcastTo));

  Future<void> broadcastTo(User user) =>
    socket.send(user, game.toJson());

  Future<void> sendError(User user, MDealError error) =>
    socket.send(user, error.toJson());
}
