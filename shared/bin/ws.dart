// Prints used to show the demo
// ignore_for_file: avoid_print

import "package:shared/network.dart";

void main() async {
  final server = ServerWebSocket(8011);
  await server.init();

  final user = User("Levi");
  final uri = Uri.parse("ws://localhost:8011");
  final socket = ClientWebSocket(uri, user);
  await socket.init();

  socket.listen((data) => print("Client got $data"));
  server.listen((user, packet) => print("Server got message from $user: $packet"));

  await socket.send({"Hello from": "$user"});
  await Future<void>.delayed(const Duration(seconds: 1));
  await server.send(user, {"Hello from": "server"});

  await Future<void>.delayed(const Duration(seconds: 1));
  await socket.dispose();
  await server.dispose();
}
