// Prints status of the game
// ignore_for_file: avoid_print

import "package:shared/network_models.dart";
import "package:shared/network_sockets.dart";

void main() async {
  final socket = ServerWebSocket(8040);
  await socket.init();
  socket.disconnections.listen((event) => print("${event.user} disconnected from ${event.roomCode}"));

  final router = Router(socket);
  router.init();



  // final serverLobby = LobbyServer(socket);
  // await serverLobby.init();
  // print("Server lobby waiting");

  // await serverLobby.gameStarted;
  // await serverLobby.dispose();
  // final game = GameServer(serverLobby.users.keys.toList(), socket);
  // await game.init();
  // print("Game started");

  // await game.isFinished;
  // await game.dispose();
  // await socket.dispose();
  // print("Game is finished!");
}
