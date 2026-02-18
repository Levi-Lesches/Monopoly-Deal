// Prints used to show the demo
// ignore_for_file: avoid_print

import "package:shared/network_data.dart";
import "package:shared/network_sockets.dart";

void main() async {
  final server = ServerWebSocket(8011);
  await server.init();

  final user = User("Levi");
  final uri = Uri.parse("ws://localhost:8011");
  final socket = ClientWebSocket(uri, user);
  await socket.init();

  socket.packets.listen((packet) => print("Client got message from server: ${packet.data}"));
  server.packets.listen((wrapper) => print("Server got message from ${wrapper.user}: ${wrapper.packet.data}"));

  socket.send(NetworkPacket("test", {"Hello from": "$user"}));
  await Future<void>.delayed(const Duration(seconds: 1));
  server.send(user, const NetworkPacket("test", {"Hello from": "server"}));

  await Future<void>.delayed(const Duration(seconds: 1));
  await socket.dispose();
  await server.dispose();
}
