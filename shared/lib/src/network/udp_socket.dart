import "dart:async";
import "dart:convert";
import "dart:io";

import "package:shared/utils.dart";

import "base_udp.dart";
import "socket.dart";
import "socket_info.dart";
import "user.dart";

final serverInfo = SocketInfo(
  // address: InternetAddress("192.168.1.210"),
  address: InternetAddress.loopbackIPv4,
  port: 8000,
);

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
  UdpClientSocket(super.user, {required int port}) :
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
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }

  final _controller = StreamController<Packet>.broadcast();
  final _subs = <StreamSubscription<void>>[];

  @override
  void listen(ClientCallback callback) {
    final sub = _controller.stream.listen(callback);
    _subs.add(sub);
  }

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
    for (final sub in _subs) {
      await sub.cancel();
    }
    _sub = null;
    _subs.clear();
  }

  final _controller = StreamController<UdpClientPacket>.broadcast();
  final _subs = <StreamSubscription<void>>[];

  @override
  void listen(ServerCallback func) => _subs.add(
    _controller.stream.listen(
      (udpPacket) => func(udpPacket.user, udpPacket.packet),
    ),
  );

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
