import "dart:async";
import "dart:convert";
import "dart:io";

import "package:collection/collection.dart";
import "package:shelf/shelf_io.dart";
import "package:shelf_web_socket/shelf_web_socket.dart";
import "package:web_socket_channel/status.dart" as status;
import "package:web_socket_channel/web_socket_channel.dart";

import "package:shared/data.dart";
import "package:shared/utils.dart";

import "socket.dart";
import "user.dart";

class ClientWebSocket extends ClientSocket {
  final Uri _uri;
  ClientWebSocket(this._uri, super.user);

  final _packetsController = StreamController<Packet>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<void>? _sub;

  @override
  Future<void> init() async {
    _channel = WebSocketChannel.connect(_uri);
    await _channel!.ready;
    _sub = _channel!.stream.listen(_handlePacket);
  }

  void _handlePacket(dynamic data) {
    final packet = ServerSocketPacket.fromJson(jsonDecode(data));
    if (packet.error case final GameError error) {
      _packetsController.addError(error);
    } else if (packet.data case final Packet packet) {
      _packetsController.add(packet);
    }
  }

  @override
  Future<void> dispose() async {
    await _channel?.sink.close(status.normalClosure);
    await _sub?.cancel();
  }

  @override
  Future<void> send(Packet packet) async {
    final body = ClientSocketPacket(user, packet);
    _channel!.sink.add(jsonEncode(body));
  }

  @override
  Stream<Packet> get packets => _packetsController.stream;
}

class ServerWebSocket extends ServerSocket {
  final int _port;
  ServerWebSocket(this._port);

  final _userSockets = <User, WebSocketChannel>{};
  final _controller = StreamController<ClientSocketPacket>.broadcast();
  final _disconnectsController = StreamController<User>.broadcast();
  final _connectionsController = StreamController<User>.broadcast();
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
    await _connectionsController.close();
    for (final socket in _userSockets.values) {
      await socket.sink.close(status.normalClosure);
    }
    _userSockets.clear();
  }

  @override
  Stream<User> get disconnects => _disconnectsController.stream;

  @override
  Stream<User> get connections => _connectionsController.stream;

  void _handleConnection(WebSocketChannel socket, _) {
    socket.stream.listen(
      (packet) => _onClientPacket(socket, packet),
      onDone: () => _onClientDisconnect(socket),
    );
  }

  void _onClientPacket(WebSocketChannel socket, String packet) {
    final packetJson = jsonDecode(packet);
    final clientPacket = ClientSocketPacket.fromJson(packetJson);
    final existingUser = _userSockets.keys.firstWhereOrNull((user) => user.name == clientPacket.user.name);
    if (existingUser == null) {
      _userSockets[clientPacket.user] = socket;
      _connectionsController.add(clientPacket.user);
    } else if (existingUser.password != clientPacket.user.password) {
      final error = GameError("Invalid password");
      final response = ServerSocketPacket(error: error);
      socket.sink.add(jsonEncode(response.toJson()));
      return;
    }
    _controller.add(clientPacket);
  }

  void _onClientDisconnect(WebSocketChannel socket) {
    final user = _userSockets.inverted[socket];
    if (user == null) return;
    _userSockets.remove(user);
    _disconnectsController.add(user);
  }

  @override
  Future<void> send(User user, Packet payload) async {
    final socket = _userSockets[user]!;
    final body = ServerSocketPacket(data: payload);
    socket.sink.add(jsonEncode(body));
  }

  @override
  Stream<ClientSocketPacket> get packets => _controller.stream;
}
