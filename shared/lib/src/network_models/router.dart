import "package:shared/data.dart";
import "package:shared/network_data.dart";
import "package:shared/network_sockets.dart";

import "room.dart";

class Router {
  final Map<RoomID, Room> rooms = {};
  final ServerSocket socket;
  Router(this.socket);

  void init() {
    socket.packets
      .where((packet) => packet.packet.type == RoomJoinPacket.name)
      .listen(joinRoom);
  }

  void joinRoom(WrappedPacket wrapper) {
    final Room? room;
    if (wrapper.roomCode == 0) {
      room = Room(socket);
      room.init();
      rooms[room.roomCode] = room;
    } else {
      room = rooms[wrapper.roomCode];
    }
    if (room == null) {
      socket.sendError(wrapper.user, GameError("Room not found"));
    } else {
      room.join(wrapper.user);
    }
  }

  Future<void> dispose() async {
    for (final room in rooms.values) {
      await room.dispose();
    }
  }
}
