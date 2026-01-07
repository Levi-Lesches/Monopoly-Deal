import "dart:async";

import "package:shared/network.dart";
import "package:shared/utils.dart";

final aliceUser = User("Alice");
final bobUser = User("Bob");

Map<User, StreamController<Packet>> clientControllers = {
  aliceUser: StreamController(),
  bobUser: StreamController(),
};
Map<User, StreamController<Packet>> serverControllers = {
  aliceUser: StreamController(),
  bobUser: StreamController(),
};

class MockServerSocket extends ServerSocket {
  final subs = <StreamSubscription<void>>[];

  @override
  Future<void> init() async { }

  @override
  Future<void> dispose() async {
    for (final sub in subs) {
      await sub.cancel();
    }
  }

  @override
  Future<void> send(User user, Packet packet) async =>
    serverControllers[user]!.add(packet);

  @override
  void listen(void Function(User, Packet) func) {
    for (final (user, controller) in clientControllers.records) {
      void callback(Packet packet) => func(user, packet);
      subs.add(controller.stream.listen(callback));
    }
  }
}

class MockClientSocket extends ClientSocket {
  MockClientSocket(super.user);

  @override Future<void> init() async { }
  @override Future<void> dispose() async =>
    sub?.cancel();

  @override Future<void> send(Packet packet) async =>
    clientControllers[user]!.add(packet);

  StreamSubscription<void>? sub;

  @override
  void listen(void Function(Packet) func) =>
    sub = serverControllers[user]!.stream.listen(func);
}
