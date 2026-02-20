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

  final _userSockets = <UserID, WebSocketChannel>{};
  final _users = <UserID, User>{};
  final _controller = StreamController<WrappedPacket>.broadcast();
  final _disconnectsController = StreamController<DisconnectionEvent>.broadcast();
  HttpServer? _server;

  @override
  Future<void> init() async {
    final handler = webSocketHandler(
      _handleConnection,
      pingInterval: const Duration(seconds: 1),
      protocols: [protocolName],
    );
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
    _users.putIfAbsent(wrapper.user.id, () => wrapper.user);
    _users[wrapper.user.id]!.roomCode = wrapper.roomCode;
    _userSockets.putIfAbsent(wrapper.user.id, () => socket);
    _controller.add(wrapper);
  }

  void _onClientDisconnect(WebSocketChannel socket) {
    final userID = _userSockets.inverted[socket];
    if (userID == null) return;
    final user = _users[userID]!;
    final roomCode = user.roomCode;
    final event = DisconnectionEvent(roomCode: roomCode, user: user);
    _disconnectsController.add(event);
    _users.remove(userID);
    _userSockets.remove(userID);
  }

  @override
  void send(User user, NetworkPacket payload) {
    final socket = _userSockets[user.id];
    socket?.sink.add(jsonEncode(payload));
  }

  @override
  Stream<WrappedPacket> get packets => _controller.stream;

  @override
  Stream<DisconnectionEvent> get disconnections => _disconnectsController.stream;
}
