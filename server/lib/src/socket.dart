import "package:shared/shared.dart";

typedef Packet = Json;

abstract class MDealSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(Player user, Packet payload);
  void listen(void Function(Player, Packet) func);
}
