import "dart:async";

import "package:shared/data.dart";
import "package:shared/network_data.dart";
import "package:shared/network_sockets.dart";

final aliceUser = User("Alice");
final bobUser = User("Bob");

class MockServerSocket extends ServerSocket {
  final Map<User, StreamController<WrappedPacket>> clientControllers = {
    aliceUser: StreamController.broadcast(),
    bobUser: StreamController.broadcast(),
  };
  final Map<User, StreamController<NetworkPacket>> serverControllers = {
    aliceUser: StreamController.broadcast(),
    bobUser: StreamController.broadcast(),
  };

  final _subs = <StreamSubscription<void>>[];
  final _controller = StreamController<WrappedPacket>.broadcast();
  final _disconnects = StreamController<DisconnectionEvent>.broadcast();

  @override
  Future<void> init() async {
    for (final controller in clientControllers.values) {
      _subs.add(controller.stream.listen(_controller.add));
      _subs.add(controller.stream.where((w) => w.packet.type == "disconnect").listen(_onDisconnect));
    }
  }

  void _onDisconnect(WrappedPacket packet) {
    _disconnects.add(DisconnectionEvent(
      roomCode: packet.roomCode,
      user: packet.user,
    ));
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _controller.close();
    for (final controller in [...clientControllers.values, ...serverControllers.values]) {
      await controller.close();
    }
  }

  @override
  Stream<DisconnectionEvent> get disconnections => _disconnects.stream;

  @override
  void send(User user, NetworkPacket packet) {
    serverControllers[user]!.add(packet);
  }

  @override
  void sendError(User user, MDealError error) {
    serverControllers[user]!.addError(error);
  }

  @override
  Stream<WrappedPacket> get packets => _controller.stream;
}

class MockClientSocket extends ClientSocket {
  final MockServerSocket server;
  MockClientSocket(super.user, this.server);

  @override Future<void> init() async { }
  @override Future<void> dispose() async {
    server.clientControllers[user]!.add(wrap(const NetworkPacket("disconnect", {})));
    await Future<void>.delayed(Duration.zero);
  }

  @override void send(NetworkPacket packet) =>
    server.clientControllers[user]!.add(wrap(packet));

  @override
  Stream<NetworkPacket> get packets => server.serverControllers[user]!.stream;
}
