// ignore_for_file: document_ignores, avoid_print, discarded_futures

import "dart:async";

import "package:shared/network_data.dart";
import "package:shared/network_models.dart";
import "package:shared/network_sockets.dart";

final Uri uri = Uri.parse("ws://localhost:8040");

Future<LobbyClient> lobbyClient(String username) async {
  final user = User(username);
  final socket = ClientWebSocket(uri, user);
  await socket.init();
  final lobby = LobbyClient(socket);
  unawaited(lobby.gameStarted.then((_) {
    lobby.dispose();
    print("$username is ready to go!");
  }));

  lobby.init();
  return lobby;
}

void main() async {
  final lobby1 = await lobbyClient("Alice");
  final lobby2 = await lobbyClient("Bob");

  final roomCode = await lobby1.join(null);
  await lobby2.join(roomCode);

  print("Everyone joined room #$roomCode");

  lobby1.markReady(isReady: true);
  lobby2.markReady(isReady: true);

  print("Everyone is ready");

  await lobby1.gameStarted;

  print("Starting game client...");

  final game = MDealClient(lobby1.socket, roomCode);

  final state = await game.gameUpdates.first;
  print("Got the game: ${state.player.name} has ${state.player.hand}");
}
