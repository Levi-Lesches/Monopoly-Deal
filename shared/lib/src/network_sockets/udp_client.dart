import "dart:async";
import "dart:convert";
import "dart:io";

import "package:shared/network_data.dart";

import "base_udp.dart";
import "socket.dart";
import "socket_info.dart";

export "socket_info.dart";

class UdpClientSocket extends ClientSocket {
  final UdpSocket _udp;
  final SocketInfo serverInfo;
  UdpClientSocket(super.user, {required int port, required this.serverInfo}) :
    _udp = UdpSocket(port: port);

  StreamSubscription<Datagram>? _udpSub;

  @override
  Future<void> init() async {
    await _udp.init();
    _udpSub = _udp.stream.listen(_handlePacket);
  }

  @override
  Future<void> dispose() async {
    await _udpSub?.cancel();
    _udpSub = null;
    await _udp.dispose();
  }

  final _controller = StreamController<NetworkPacket>.broadcast();

  void _handlePacket(Datagram datagram) {
    final jsonString = String.fromCharCodes(datagram.data);
    final json = jsonDecode(jsonString);
    final packet = NetworkPacket.fromJson(json);
    _controller.add(packet);
  }

  @override
  Future<void> send(NetworkPacket packet) async {
    final wrapper = wrap(packet);
    final jsonString = jsonEncode(wrapper);
    _udp.send(jsonString.codeUnits, destination: serverInfo);
  }

  @override
  Stream<NetworkPacket> get packets => _controller.stream;
}
