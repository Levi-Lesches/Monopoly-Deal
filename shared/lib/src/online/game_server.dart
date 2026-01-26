import "dart:async";

import "package:collection/collection.dart";
import "package:shared/data.dart";
import "package:shared/game.dart";
import "package:shared/network.dart";
import "package:shared/utils.dart";

import "game_packets.dart";

class Server {
  final _finishedCompleter = Completer<void>();
  final Game game;
  final ServerSocket socket;
  final List<User> users;
  List<RevealedPlayer> get players => game.players;

  Server(this.users, this.socket) :
    game = Game([for (final user in users) RevealedPlayer(user.name)]);

  Future<void> init() async {
    socket.packets.listen(handlePacket);
  }

  Future<void> get isFinished => _finishedCompleter.future;

  Future<void> handlePacket(ClientSocketPacket clientPacket) async {
    final ClientSocketPacket(:user, data:packet) = clientPacket;
    final gamePacket = safely(() => GamePacket.fromJson(packet, GameClientPacketType.fromJson));
    if (gamePacket == null) return;
    switch (gamePacket.type) {
      case .game:
        await broadcastTo(user);
      case .action:
        final action = PlayerAction.fromJson(game, gamePacket.data);
        if (action.player.name != user.name) return;
        await handleAction(user, action);
      case .response:
        final response = InterruptionResponse.fromJson(game, gamePacket.data);
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

  Future<void> dispose() async { }

  Future<void> broadcastToAll() async {
    for (final user in users) {
      await broadcastTo(user);
    }
    final winner = players.firstWhereOrNull((p) => p.isWinner);
    if (winner != null) _finishedCompleter.complete();
  }

  Future<void> broadcastTo(User user) async {
    final player = game.findPlayer(user.name);
    final state = game.getStateFor(player);
    final body = GamePacket(type: GameServerPacketType.game, data: state.toJson());
    final json = body.toJson();
    await socket.send(user, json);
  }

  Future<void> sendError(User user, MDealError error) async {
    final body = GamePacket(type: GameServerPacketType.error, data: error.toJson());
    await socket.send(user, body.toJson());
  }
}
