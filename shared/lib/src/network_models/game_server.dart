import "dart:async";
import "package:collection/collection.dart";

import "package:shared/data.dart";
import "package:shared/game.dart";
import "package:shared/network_data.dart";

import "room.dart";

class GameServer extends RoomEntity {
  final _finishedCompleter = Completer<void>();
  final Game game;

  @override
  final List<User> allUsers;

  GameServer(this.allUsers, super.socket) :
    game = Game([for (final user in allUsers) RevealedPlayer(user.name)]);

  List<RevealedPlayer> get players => game.players;
  Future<void> get isFinished => _finishedCompleter.future;

  void log(String message) {
    game.log(SimpleEvent(message));
    broadcastToAll();
  }

  @override
  void handlePacket(WrappedPacket wrapper) {
    final WrappedPacket(:user, :packet) = wrapper;
    switch (packet.type) {
      case "game_request_state":
        broadcastTo(user);
      case "game_action":
        final action = PlayerAction.fromJson(game, packet.data);
        if (action.player.name != user.name) return;
        handleAction(user, action);
      case "game_response":
        final response = InterruptionResponse.fromJson(game, packet.data);
        if (response.player.name != user.name) return;
        handleResponse(user, response);
    }
  }

  void handleAction(User user, PlayerAction action) {
    try {
      game.handleAction(action);
      broadcastToAll();
    } on MDealError catch (error) {
      sendError(user, error);
    }
  }

  void handleResponse(User user, InterruptionResponse response) {
    try {
      game.handleResponse(response);
      broadcastToAll();
    } on MDealError catch (error) {
      sendError(user, error);
    }
  }

  @override
  void broadcastToAll() {
    allUsers.forEach(broadcastTo);
    final winner = players.firstWhereOrNull((p) => p.isWinner);
    if (winner != null) _finishedCompleter.complete();
  }

  void broadcastTo(User user) {
    final player = game.findPlayer(user.name);
    final state = game.getStateFor(player);
    final packet = NetworkPacket("game_state", state.toJson());
    socket.send(user, packet);
  }

  void sendError(User user, MDealError error) {
    socket.sendError(user, error);
  }
}
