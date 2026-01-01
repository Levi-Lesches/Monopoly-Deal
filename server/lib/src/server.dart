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

  Future<void> handlePacket(Player player, Packet packet) async {
    // {
    //  "type": "action" | "response",
    //  "data": Json,
    // }
    final type = packet["type"] as String;
    final data = packet["data"] as Json;
    switch (type) {
      case "action":
        final action = PlayerAction.fromJson(game, data);
        if (action.player.name != player.name) return;
        await handleAction(player, action);
      case "response":
        final response = InterruptionResponse.fromJson(game, data);
        if (response.player.name != player.name) return;
        await handleResponse(player, response);
    }
  }

  Future<void> handleAction(Player player, PlayerAction action) async {
    try {
      game.handleAction(action);
      await broadcastToAll();
    } on MDealError catch (error) {
      await sendError(player, error);
    }
  }

  Future<void> handleResponse(Player player, InterruptionResponse response) async {
    try {
      game.handleResponse(response);
      await broadcastToAll();
    } on MDealError catch (error) {
      await sendError(player, error);
    }
  }

  Future<void> dispose() async {
    await socket.dispose();
  }

  Future<void> broadcastToAll() =>
    Future.wait(players.map(broadcastTo));

  Future<void> broadcastTo(RevealedPlayer player) =>
    socket.send(player, game.getStateFor(player).toJson());

  Future<void> sendError(Player player, MDealError error) =>
    socket.send(player, error.toJson());
}
