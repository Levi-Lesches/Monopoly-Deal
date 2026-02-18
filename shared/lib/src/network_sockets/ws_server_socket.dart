import "dart:async";
import "dart:convert";
import "dart:io";

import "package:shared/network_data.dart";
import "package:shelf/shelf_io.dart";
import "package:shelf_web_socket/shelf_web_socket.dart";
import "package:web_socket_channel/status.dart" as status;
import "package:web_socket_channel/web_socket_channel.dart";

import "package:shared/utils.dart";

import "socket.dart";

class ServerWebSocket extends ServerSocket {
  final int _port;
  ServerWebSocket(this._port);

  final _userSockets = <User, WebSocketChannel>{};
  final _userRooms = <User, int>{};
  final _controller = StreamController<WrappedPacket>.broadcast();
  final _disconnectsController = StreamController<DisconnectionEvent>.broadcast();
  HttpServer? _server;

  @override
  Future<void> init() async {
    final handler = webSocketHandler(_handleConnection);
    _server = await serve(handler, "0.0.0.0", _port);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
    await _disconnectsController.close();
    // Need to make a copy of the map since closing sockets changes the length
    for (final socket in _userSockets.values.toList()) {
      await socket.sink.close(status.normalClosure);
    }
    _userSockets.clear();
    _userRooms.clear();
    await _server?.close();
  }

  void _handleConnection(WebSocketChannel socket, _) {
    socket.stream.listen(
      (packet) => _onClientPacket(socket, packet),
      onDone: () => _onClientDisconnect(socket),
    );
  }

  void _onClientPacket(WebSocketChannel socket, String packet) {
    final packetJson = jsonDecode(packet);
    final wrapper = WrappedPacket.fromJson(packetJson);
    _userSockets.putIfAbsent(wrapper.user, () => socket);
    _controller.add(wrapper);
  }

  void _onClientDisconnect(WebSocketChannel socket) {
    final user = _userSockets.inverted[socket];
    if (user == null) return;
    _userSockets.remove(user);
    final roomCode = _userRooms[user];
    if (roomCode == null) return;
    final event = DisconnectionEvent(roomCode: roomCode, user: user);
    _disconnectsController.add(event);
  }

  @override
  void send(User user, NetworkPacket payload) {
    final socket = _userSockets[user];
    socket?.sink.add(jsonEncode(payload));
  }

  @override
  Stream<WrappedPacket> get packets => _controller.stream;

  @override
  Stream<DisconnectionEvent> get disconnections => _disconnectsController.stream;
}
