import "dart:async";

import "package:shared/shared.dart";

import "socket.dart";

class Server {
  final Game game;
  final ServerSocket socket;
  final List<User> users;
  List<RevealedPlayer> get players => game.players;

  Server(this.users, this.socket) :
    game = Game([for (final user in users) RevealedPlayer(user.name)]);

  Future<void> init() async {
    await socket.init();
    socket.listen(handlePacket);
    await broadcastToAll();
  }

  Future<void> handlePacket(User user, Packet packet) async {
    // {
    //  "type": "action" | "response",
    //  "data": Json,
    //  "password": string,
    // }
    final type = packet["type"] as String;
    final data = packet["data"] as Json;
    final password = packet["password"] as String;
    if (password != user.password) {
      await sendError(user, GameError.wrongPassword);
      return;
    }
    switch (type) {
      case "action":
        final action = PlayerAction.fromJson(game, data);
        if (action.player.name != user.name) return;
        await handleAction(user, action);
      case "response":
        final response = InterruptionResponse.fromJson(game, data);
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

  Future<void> broadcastTo(User user) async {
    final player = game.findPlayer(user.name);
    final body = {
      "type": "game",
      "data": game.getStateFor(player).toJson(),
    };
    await socket.send(user, body);
  }

  Future<void> sendError(User user, MDealError error) =>
    socket.send(user, error.toJson());
}
