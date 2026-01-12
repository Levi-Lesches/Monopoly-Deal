import "dart:async";
import "dart:convert";
import "dart:io";

import "package:shelf/shelf_io.dart";
import "package:shelf_web_socket/shelf_web_socket.dart";
import "package:web_socket_channel/status.dart" as status;
import "package:web_socket_channel/web_socket_channel.dart";

import "package:shared/network.dart";

class ClientWebSocket extends ClientSocket {
  final Uri _uri;
  ClientWebSocket(this._uri, super.user);

  late final Stream<dynamic> _stream;
  WebSocketChannel? _channel;

  @override
  Future<void> init() async {
    _channel = WebSocketChannel.connect(_uri);
    await _channel!.ready;
    _stream = _channel!.stream.asBroadcastStream();
  }

  @override
  Future<void> dispose() async {
    await _channel?.sink.close(status.normalClosure);
  }

  @override
  Future<void> send(Packet packet) async {
    final body = ClientSocketPacket(user, packet);
    _channel!.sink.add(jsonEncode(body));
  }

  @override
  StreamSubscription<void> listen(ClientCallback callback) =>
    _stream.asBroadcastStream().listen((data) => callback(jsonDecode(data)));
}

class ServerWebSocket extends ServerSocket {
  final int _port;
  ServerWebSocket(this._port);

  final _userSockets = <User, WebSocketChannel>{};
  final _controller = StreamController<ClientSocketPacket>.broadcast();
  HttpServer? _server;

  @override
  Future<void> init() async {
    final handler = webSocketHandler(_handleConnection);
    _server = await serve(handler, "0.0.0.0", _port);
  }

  @override
  Future<void> dispose() async {
    await _server?.close();
    await _controller.close();
    for (final socket in _userSockets.values) {
      await socket.sink.close(status.normalClosure);
    }
    _userSockets.clear();
  }

  void _handleConnection(WebSocketChannel socket, _) =>
    socket.stream.listen((packet) => _onClientPacket(socket, packet));

  void _onClientPacket(WebSocketChannel socket, dynamic packet) {
    final packetJson = jsonDecode(packet);
    final clientPacket = ClientSocketPacket.fromJson(packetJson);
    _userSockets[clientPacket.user] = socket;
    _controller.add(clientPacket);
  }

  @override
  Future<void> send(User user, Packet payload) async {
    final socket = _userSockets[user]!;
    socket.sink.add(jsonEncode(payload));
  }

  @override
  StreamSubscription<void> listen(ServerCallback func) =>
    _controller.stream.listen((packet) => func(packet.user, packet.packet));
}
