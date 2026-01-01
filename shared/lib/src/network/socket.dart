import "dart:async";

import "package:shared/data.dart";
import "package:shared/utils.dart";

typedef Packet = Json;

abstract class ServerSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(User user, Packet payload);
  void listen(void Function(User, Packet) func);
}

abstract class ClientSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(Packet payload);
  void listen(void Function(Packet) func);
}
