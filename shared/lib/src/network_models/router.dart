import "dart:math";

import "package:shared/data.dart";
import "package:shared/network_data.dart";
import "package:shared/network_sockets.dart";

import "room.dart";

extension <E> on List<E> {
  static final _random = Random();
  E? randomChoice() => isEmpty ? null : this[_random.nextInt(length)];
}

class Router {
  final Map<RoomID, Room> rooms = {};
  final ServerSocket socket;
  Router(this.socket);

  final _availableRoomCodes = <int>[
    for (int i = 1; i <= 9999; i++)
      i,
  ];

  void init() {
    socket.packets
      .where((packet) => packet.packet.type == RoomJoinPacket.name)
      .listen(joinRoom);
  }

  void _removeRoom(int roomCode) {
    rooms.remove(roomCode);
    _availableRoomCodes.add(roomCode);
  }

  void joinRoom(WrappedPacket wrapper) {
    final Room? room;
    if (wrapper.roomCode == 0) {
      final roomCode = _availableRoomCodes.randomChoice();
      if (roomCode == null) {
        socket.sendError(wrapper.user, GameError("No rooms left, try again later"));
        return;
      }
      _availableRoomCodes.remove(roomCode);
      room = Room(roomCode, socket, onClosed: _removeRoom);
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
