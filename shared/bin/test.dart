import "package:shared/src/network_models/router.dart";
import "package:shared/src/network_sockets/ws_server_socket.dart";

void main() async {
  final socket = ServerWebSocket(5000);
  final router = Router(socket);
  await socket.init();
  router.init();
}
