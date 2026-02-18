import "dart:async";

import "package:shared/network_data.dart";
import "package:shared/network_sockets.dart";

final aliceUser = User("Alice");
final bobUser = User("Bob");

Map<User, StreamController<WrappedPacket>> clientControllers = {
  aliceUser: StreamController(),
  bobUser: StreamController(),
};
Map<User, StreamController<NetworkPacket>> serverControllers = {
  aliceUser: StreamController(),
  bobUser: StreamController(),
};

class MockServerSocket extends ServerSocket {
  final _subs = <StreamSubscription<void>>[];
  final _controller = StreamController<WrappedPacket>.broadcast();

  @override
  Future<void> init() async {
    for (final controller in clientControllers.values) {
      _subs.add(controller.stream.listen(_controller.add));
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
  Stream<DisconnectionEvent> get disconnections => const Stream.empty();

  @override
  void sendToUser(User user, NetworkPacket packet) =>
    serverControllers[user]!.add(packet);

  @override
  Stream<WrappedPacket> get packets => _controller.stream;
}

class MockClientSocket extends ClientSocket {
  MockClientSocket(super.user);

  @override Future<void> init() async { }
  @override Future<void> dispose() async { }

  @override void send(NetworkPacket packet)  =>
    clientControllers[user]!.add(wrap(packet));

  @override
  Stream<NetworkPacket> get packets => serverControllers[user]!.stream;
}
