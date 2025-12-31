import "package:shared/shared.dart";

typedef Packet = Json;

abstract class MDealSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(User user, Packet payload);
  void listen(void Function(User, Packet) func);
}
