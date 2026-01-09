// ignore_for_file: document_ignores, avoid_print, discarded_futures

import "dart:io";

import "package:shared/network.dart";
import "package:shared/online.dart";

void main() async {
  final david = User("david");
  final davidSocket = UdpClientSocket(david, port: 8002, serverInfo: SocketInfo(address: InternetAddress.loopbackIPv4, port: 8000));
  final davidLobby = LobbyClient(davidSocket);
  await davidSocket.init();
  await davidLobby.init();
  // ignore: unawaited_futures
  davidLobby.gameStarted.then((_) { davidLobby.dispose(); print("David is ready to go!"); });

  await davidLobby.join();
  await davidLobby.markReady(isReady: true);

  print("Everyone joined and is ready");

  await davidLobby.gameStarted;

  final davidGame = MDealClient(davidSocket);
  await davidGame.init();
  davidGame.gameUpdates.listen((game) => print("David got the game: ${game.player.name} has ${game.player.hand}"));
}
