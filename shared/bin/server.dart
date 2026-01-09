// Prints status of the game
// ignore_for_file: avoid_print

import "package:shared/network.dart";
import "package:shared/online.dart";

void main() async {
  final serverSocket = UdpServerSocket(port: 8010);
  final serverLobby = LobbyServer(serverSocket);
  await serverSocket.init();
  await serverLobby.init();
  print("Server lobby waiting");
  await serverLobby.gameStarted;
  print("Starting game!");
  await serverLobby.dispose();
  final game = Server(serverLobby.users.keys.toList(), serverSocket);
  await game.init();
  print("Game started");
}
