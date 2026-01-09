// unawaited .then() calls so we can print whenever needed
// ignore_for_file: avoid_print

import "package:shared/network.dart";
import "package:shared/online.dart";

void main() async {
  final serverSocket = UdpServerSocket(port: 8000);
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

  // print("Disposing...");
  // await game.dispose();
  // await serverLobby.dispose();
  // await serverSocket.dispose();

  // return;

  // serverLobby.gameStarted.then((_) => print("Server is ready to go!"));

  // final levi = User("Levi");
  // final leviSocket = UdpClientSocket(levi, port: 8001);
  // final leviLobby = LobbyClient(socket: leviSocket, user: levi);
  // await leviSocket.init();
  // await leviLobby.init();
  // leviLobby.gameStarted.then((_) => print("Levi is ready to go!"));

  // final david = User("david");
  // final davidSocket = UdpClientSocket(david, port: 8002);
  // final davidLobby = LobbyClient(socket: davidSocket, user: david);
  // await davidSocket.init();
  // await davidLobby.init();
  // davidLobby.gameStarted.then((_) => print("David is ready to go!"));

  // print("Joining...");
  // print("Levi joined: ${await leviLobby.join()}");
  // print("David joined: ${await davidLobby.join()}");

  // print("Everyone joined! Marking everyone as ready...");
  // await leviLobby.markReady();
  // await davidLobby.markReady();
  // print("Everyone is ready!");

  // await Future<void>.delayed(const Duration(seconds: 1));

  // await serverSocket.dispose();
  // await leviSocket.dispose();
  // await davidSocket.dispose();
  // await serverLobby.dispose();
  // await leviLobby.dispose();
  // await davidLobby.dispose();
}
