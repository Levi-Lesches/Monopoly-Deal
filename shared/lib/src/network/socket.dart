import "dart:async";

import "package:shared/data.dart";
import "package:shared/utils.dart";

typedef Packet = Json;

typedef ServerCallback = void Function(User, Packet);
abstract class ServerSocket {
  Future<void> init();
  Future<void> dispose();
  Future<void> send(User user, Packet payload);
  StreamSubscription<void> listen(ServerCallback func);
}

typedef ClientCallback = void Function(Packet);
abstract class ClientSocket {
  final User user;
  ClientSocket(this.user);

  Future<void> init();
  Future<void> dispose();
  Future<void> send(Packet payload);
  StreamSubscription<void> listen(ClientCallback func);
}
