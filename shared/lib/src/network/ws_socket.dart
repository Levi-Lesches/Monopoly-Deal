import "dart:async";
import "dart:convert";
import "dart:io";

import "package:shelf/shelf_io.dart";
import "package:shelf_web_socket/shelf_web_socket.dart";
import "package:web_socket_channel/status.dart" as status;
import "package:web_socket_channel/web_socket_channel.dart";

import "package:shared/utils.dart";

import "socket.dart";
import "user.dart";

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
  final _disconnectsController = StreamController<User>.broadcast();
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
    await _disconnectsController.close();
    for (final socket in _userSockets.values) {
      await socket.sink.close(status.normalClosure);
    }
    _userSockets.clear();
  }

  @override
  Stream<User> get disconnects => _disconnectsController.stream;

  void _handleConnection(WebSocketChannel socket, _) {
    socket.stream.listen(
      (packet) => _onClientPacket(socket, packet),
      onDone: () => _onClientDisconnect(socket),
    );
  }

  void _onClientPacket(WebSocketChannel socket, String packet) {
    final packetJson = jsonDecode(packet);
    final clientPacket = ClientSocketPacket.fromJson(packetJson);
    _userSockets[clientPacket.user] = socket;
    _controller.add(clientPacket);
  }

  void _onClientDisconnect(WebSocketChannel socket) {
    final user = _userSockets.inverted[socket];
    if (user == null) return;
    _disconnectsController.add(user);
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
