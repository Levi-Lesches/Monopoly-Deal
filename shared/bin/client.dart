// ignore_for_file: document_ignores, avoid_print, discarded_futures

import "package:shared/network.dart";
import "package:shared/online.dart";

void main() async {
  // final levi = User("Levi");
  // final leviSocket = UdpClientSocket(levi, port: 8001);
  // final leviLobby = LobbyClient(leviSocket);
  // await leviSocket.init();
  // await leviLobby.init();
  // // ignore: unawaited_futures
  // leviLobby.gameStarted.then((_) { leviLobby.dispose(); print("Levi is ready to go!"); });

  final david = User("david");
  final davidSocket = UdpClientSocket(david, port: 8002);
  final davidLobby = LobbyClient(davidSocket);
  await davidSocket.init();
  await davidLobby.init();
  // ignore: unawaited_futures
  davidLobby.gameStarted.then((_) { davidLobby.dispose(); print("David is ready to go!"); });

  await davidLobby.join();
  await davidLobby.markReady(isReady: true);

  // await leviLobby.join();
  // await leviLobby.markReady(isReady: true);

  print("Everyone joined and is ready");

  await davidLobby.gameStarted;

  // print("Levi is starting the game");

  // final leviGame = MDealClient(leviSocket);
  // await leviGame.init();
  // leviGame.gameUpdates.listen((game) => print("Levi got the game: ${game.player.name} has ${game.player.hand}"));

  final davidGame = MDealClient(davidSocket);
  await davidGame.init();
  davidGame.gameUpdates.listen((game) => print("David got the game: ${game.player.name} has ${game.player.hand}"));
}
