// Prints status of the game
// ignore_for_file: avoid_print

import "package:shared/network_models.dart";
import "package:shared/network_sockets.dart";

void main() async {
  final socket = ServerWebSocket(8040);
  await socket.init();
  print("Serving on ws://localhost:8040");

  final router = Router(socket);
  router.init();
}
