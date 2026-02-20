import "dart:async";
import "dart:convert";

import "package:web_socket_channel/status.dart" as status;
import "package:web_socket_channel/web_socket_channel.dart";

import "package:shared/data.dart";
import "package:shared/network_data.dart";
import "socket.dart";

class ClientWebSocket extends ClientSocket {
  final Uri _uri;
  ClientWebSocket(this._uri, super.user);

  final _packetsController = StreamController<NetworkPacket>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<void>? _sub;

  @override
  bool get isConnected => _channel != null && _channel!.closeCode == null;

  @override
  Future<void> init() async {
    _channel = WebSocketChannel.connect(
      _uri,
      protocols: [protocolName],
    );
    await _channel!.ready;
    _sub = _channel!.stream.listen(_handlePacket, onDone: dispose);
  }

  void _handlePacket(dynamic data) {
    final packet = NetworkPacket.fromJson(jsonDecode(data));
    if (packet.type == "error") {
      final error = GameError.fromJson(packet.data);
      _packetsController.addError(error);
    } else {
      _packetsController.add(packet);
    }
  }

  @override
  Future<void> dispose() async {
    await _channel?.sink.close(status.normalClosure);
    await _sub?.cancel();
    await _packetsController.close();
  }

  @override
  void send(NetworkPacket packet) {
    final wrapper = wrap(packet);
    _channel!.sink.add(jsonEncode(wrapper));
  }

  @override
  Stream<NetworkPacket> get packets => _packetsController.stream;
}
