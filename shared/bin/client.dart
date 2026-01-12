// ignore_for_file: document_ignores, avoid_print, discarded_futures

import "package:shared/network.dart";
import "package:shared/online.dart";

void main() async {
  final david = User("david");
  final uri = Uri.parse("ws://localhost:8011");
  final davidSocket = ClientWebSocket(uri, david);
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
