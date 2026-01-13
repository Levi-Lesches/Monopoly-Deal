import "dart:async";
import "dart:convert";
import "dart:io";

import "base_udp.dart";
import "socket.dart";
import "socket_info.dart";
import "user.dart";

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

  final _controller = StreamController<Packet>.broadcast();

  @override
  StreamSubscription<void> listen(ClientCallback callback) =>
    _controller.stream.listen(callback);

  void _handlePacket(Datagram datagram) {
    final jsonString = String.fromCharCodes(datagram.data);
    final packet = jsonDecode(jsonString);
    _controller.add(packet["packet"]);
  }

  @override
  Future<void> send(Packet packet) async {
    final udpPacket = ClientSocketPacket(user, packet);
    final jsonString = jsonEncode(udpPacket.toJson());
    _udp.send(jsonString.codeUnits, destination: serverInfo);
  }
}

class UdpServerSocket extends ServerSocket {
  final UdpSocket _udp;
  final _controller = StreamController<ClientSocketPacket>.broadcast();
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
  StreamSubscription<void> listen(ServerCallback func) => _controller.stream
    .listen((udpPacket) => func(udpPacket.user, udpPacket.packet));

  void parsePacket(Datagram datagram) {
    final jsonString = String.fromCharCodes(datagram.data);
    final json = jsonDecode(jsonString);
    final packet = ClientSocketPacket.fromJson(json);
    _clients[packet.user] = SocketInfo.fromDatagram(datagram);
    _controller.add(packet);
  }

  @override
  Future<void> send(User user, Packet payload) async {
    final socket = _clients[user];
    if (socket == null) throw ArgumentError("Unrecognized user: $user");
    final udpPacket = ServerSocketPacket(payload);
    final jsonString = jsonEncode(udpPacket.toJson());
    _udp.send(jsonString.codeUnits, destination: socket);
  }
}
