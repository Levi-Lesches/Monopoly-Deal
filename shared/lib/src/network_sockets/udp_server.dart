import "dart:async";
import "dart:convert";
import "dart:io";

import "package:shared/network_data.dart";

import "base_udp.dart";
import "socket.dart";
import "socket_info.dart";

export "socket_info.dart";

class UdpServerSocket extends ServerSocket {
  final UdpSocket _udp;
  final _controller = StreamController<WrappedPacket>.broadcast();
  final _clients = <User, SocketInfo>{};

  UdpServerSocket({required int port}) :
    _udp = UdpSocket(port: port);

  StreamSubscription<Datagram>? _sub;

  @override
  Future<void> init() async {
    await _udp.init();
    _sub = _udp.stream.listen(parsePacket);
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _udp.dispose();
    await _controller.close();
    _clients.clear();
    _sub = null;
  }

  @override
  final Stream<DisconnectionEvent> disconnections = const Stream<DisconnectionEvent>.empty();

  @override
  Stream<WrappedPacket> get packets => _controller.stream;

  void parsePacket(Datagram datagram) {
    final jsonString = String.fromCharCodes(datagram.data);
    final json = jsonDecode(jsonString);
    final packet = WrappedPacket.fromJson(json);
    _clients[packet.user] = SocketInfo.fromDatagram(datagram);
    _controller.add(packet);
  }

  @override
  Future<void> send(User user, NetworkPacket packet) async {
    final socket = _clients[user];
    if (socket == null) throw ArgumentError("Unrecognized user: $user");
    final jsonString = jsonEncode(packet);
    _udp.send(jsonString.codeUnits, destination: socket);
  }
}
