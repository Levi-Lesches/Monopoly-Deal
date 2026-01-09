import "dart:async";
import "dart:convert";
import "dart:io";

import "package:shared/utils.dart";

import "base_udp.dart";
import "socket.dart";
import "socket_info.dart";
import "user.dart";

class UdpServerPacket {
  final Packet packet;
  const UdpServerPacket(this.packet);

  UdpServerPacket.fromJson(Json json) :
    packet = json["packet"];

  Json toJson() => {
    "packet": packet,
  };
}

class UdpClientPacket {
  final User user;
  final Packet packet;
  const UdpClientPacket(this.user, this.packet);

  UdpClientPacket.fromJson(Json json) :
    user = User.fromJson(json["user"]),
    packet = json["packet"];

  Json toJson() => {
    "user": user.toJson(),
    "packet": packet,
  };
}

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
    final udpPacket = UdpClientPacket(user, packet);
    final jsonString = jsonEncode(udpPacket.toJson());
    _udp.send(jsonString.codeUnits, destination: serverInfo);
  }
}

class UdpServerSocket extends ServerSocket {
  final UdpSocket _udp;
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
    _sub = null;
  }

  final _controller = StreamController<UdpClientPacket>.broadcast();

  @override
  StreamSubscription<void> listen(ServerCallback func) => _controller.stream
    .listen((udpPacket) => func(udpPacket.user, udpPacket.packet));

  final _clients = <User, SocketInfo>{};
  void parsePacket(Datagram datagram) {
    final jsonString = String.fromCharCodes(datagram.data);
    final json = jsonDecode(jsonString);
    final packet = UdpClientPacket.fromJson(json);
    _clients[packet.user] = SocketInfo.fromDatagram(datagram);
    _controller.add(packet);
  }

  @override
  Future<void> send(User user, Packet payload) async {
    final socket = _clients[user];
    if (socket == null) throw ArgumentError("Unrecognized user: $user");
    final udpPacket = UdpServerPacket(payload);
    final jsonString = jsonEncode(udpPacket.toJson());
    _udp.send(jsonString.codeUnits, destination: socket);
  }
}
