// Prints status of the game
// ignore_for_file: avoid_print

import "package:shared/network.dart";
import "package:shared/online.dart";

void main() async {
  while (true) {
    final serverSocket = ServerWebSocket(8011);
    await serverSocket.init();
    final serverLobby = LobbyServer(serverSocket);
    await serverLobby.init();
    print("Server lobby waiting");

    await serverLobby.gameStarted;
    await serverLobby.dispose();
    final game = Server(serverLobby.users.keys.toList(), serverSocket);
    await game.init();
    print("Game started");

    await game.isFinished;
    await game.dispose();
    await serverSocket.dispose();
    print("Game is finished!");
  }
}
