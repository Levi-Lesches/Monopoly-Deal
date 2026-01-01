import "package:shared/shared.dart";

typedef Packet = Json;

abstract class ServerSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(Player user, Packet payload);
  void listen(void Function(Player, Packet) func);
}

abstract class ClientSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(Packet payload);
  void listen(void Function(Packet) func);
}
