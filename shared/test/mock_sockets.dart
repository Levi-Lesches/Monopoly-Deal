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
  final _subs = <StreamSubscription<void>>[];
  final _controller = StreamController<(User, Packet)>.broadcast();

  @override
  Future<void> init() async {
    for (final (user, controller) in clientControllers.records) {
      void callback(Packet packet) => _controller.add( (user, packet) );
      _subs.add(controller.stream.listen(callback));
    }
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _controller.close();
  }

  @override
  Stream<User> get disconnects => const Stream.empty();

  @override
  Future<void> send(User user, Packet packet) async =>
    serverControllers[user]!.add(packet);

  @override
  StreamSubscription<void> listen(void Function(User, Packet) func) =>
    _controller.stream.listen((record) => func(record.$1, record.$2));
}

class MockClientSocket extends ClientSocket {
  MockClientSocket(super.user);

  @override Future<void> init() async { }
  @override Future<void> dispose() async { }

  @override Future<void> send(Packet packet) async =>
    clientControllers[user]!.add(packet);

  @override
  StreamSubscription<void> listen(void Function(Packet) func) =>
    serverControllers[user]!.stream.listen(func);
}
