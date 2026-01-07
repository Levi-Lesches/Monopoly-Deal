import "package:shared/network.dart";

void main() async {
  final serverSocket = UdpServerSocket(port: 8000);
  final serverLobby = LobbyServer(serverSocket);
  await serverSocket.init();
  await serverLobby.init();
  serverLobby.gameStarted.then((_) => print("Server is ready to go!"));

  final levi = User("Levi");
  final leviSocket = UdpClientSocket(levi, port: 8001);
  final leviLobby = LobbyClient(socket: leviSocket, user: levi);
  await leviSocket.init();
  await leviLobby.init();
  leviLobby.gameStarted.then((_) => print("Levi is ready to go!"));

  final david = User("david");
  final davidSocket = UdpClientSocket(david, port: 8002);
  final davidLobby = LobbyClient(socket: davidSocket, user: david);
  await davidSocket.init();
  await davidLobby.init();
  davidLobby.gameStarted.then((_) => print("David is ready to go!"));

  print("Joining...");
  print("Levi joined: ${await leviLobby.join()}");
  print("David joined: ${await davidLobby.join()}");

  print("Everyone joined! Marking everyone as ready...");
  await leviLobby.markReady();
  await davidLobby.markReady();
  print("Everyone is ready!");

  await Future<void>.delayed(const Duration(seconds: 1));

  await serverSocket.dispose();
  await leviSocket.dispose();
  await davidSocket.dispose();
  await serverLobby.dispose();
  await leviLobby.dispose();
  await davidLobby.dispose();
}
