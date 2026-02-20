import "package:shared/shared.dart";
import "package:test/test.dart";

import "mock_sockets.dart";

Future<(MockServerSocket, MockClientSocket, MockClientSocket)> initSockets() async {
  final server = MockServerSocket();
  final alice = MockClientSocket(aliceUser, server);
  final bob = MockClientSocket(bobUser, server);
  await server.init();
  addTearDown(() async {
    await alice.dispose();
    await bob.dispose();
    await server.dispose();
  });
  return (server, alice, bob);
}

Future<(Router, LobbyClient, LobbyClient)> initLobbies({bool ignore = true}) async {
  final (server, aliceSocket, bobSocket) = await initSockets();
  final router = Router(server);
  final alice = LobbyClient(aliceSocket);
  final bob = LobbyClient(bobSocket);
  router.init();
  alice.init();
  bob.init();
  if (ignore) {
    alice.gameStarted.ignore();
    bob.gameStarted.ignore();
  }
  addTearDown(() async {
    await alice.dispose();
    await bob.dispose();
    await router.dispose();
  });
  return (router, alice, bob);
}

void main() => group("[rooms]", () {
  test("cannot join a room that doesn't exist", () async {
    final (router, alice, bob) = await initLobbies();
    expect(alice.join(100), throwsA(isA<GameError>()));
    await Future<void>.delayed(Duration.zero);
  });

  test("joining room=null gives a new random room", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(alice.socket.roomCode, roomCode);
    expect(roomCode, isNot(0));
    expect(roomCode, greaterThan(0));
    expect(roomCode, lessThan(10_000));
    await Future<void>.delayed(Duration.zero);
  });

  test("a second player can join an open room", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));
    final bobCode = await bob.join(roomCode);
    expect(bobCode, roomCode);
  });

  test("a player cannot join a room with a duplicate name", () async {
    final (router, alice, bob) = await initLobbies();
    final (router2, alice2, bob2) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));
    expect(alice2.join(roomCode), throwsA(isA<GameError>()));
  });

  test("disconnections are detected", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));
    expect(router.socket.disconnections, emits(isA<DisconnectionEvent>()
      .having((event) => event.user.id, "userID", alice.user.id)
      .having((event) => event.user.name, "name", alice.user.name)
      .having((event) => event.roomCode, "roomCode", roomCode)
    ));
    await alice.socket.dispose();
  });

  test("Rooms close when no users are left", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));

    final room = router.rooms[roomCode];
    expect(room, isNotNull); if (room == null) return;
    expect(room.users, isNotEmpty);
    expect(room.users.first.isConnected, isTrue);

    await alice.socket.dispose();
    expect(router.rooms, isEmpty);
  });

  test("Rooms do not close when a user is left", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));
    await bob.join(roomCode);

    final room = router.rooms[roomCode];
    expect(room, isNotNull); if (room == null) return;
    expect(room.users, hasLength(2));

    await alice.socket.dispose();
    expect(router.rooms, isNotEmpty);
    expect(room.users.firstWhere((u) => u.name == aliceUser.name).isConnected, isFalse);
    expect(room.users.firstWhere((u) => u.name == bobUser.name).isConnected, isTrue);
  });

  test("Users can re-join a room", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));
    await bob.join(roomCode);

    final room = router.rooms[roomCode];
    expect(room, isNotNull); if (room == null) return;
    expect(room.users, hasLength(2));

    await alice.socket.dispose();
    expect(router.rooms, isNotEmpty);
    expect(room.users.firstWhere((u) => u.name == aliceUser.name).isConnected, isFalse);

    await alice.socket.init();
    await alice.join(roomCode);
    expect(alice.socket.roomCode, roomCode);
    expect(room.users.firstWhere((u) => u.name == aliceUser.name).isConnected, isTrue);
  });

  test("Room starts when everyone is ready", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));
    await bob.join(roomCode);

    expect(alice.gameStarted, completes);
    expect(bob.gameStarted, completes);
    expect(router.rooms.values.first.hasStarted, isFalse);
    alice.markReady(isReady: true);
    bob.markReady(isReady: true);
    await Future<void>.delayed(Duration.zero);
    expect(router.rooms.values.first.hasStarted, isTrue);
  });

  test("Room starts when someone disconnects and re-joined", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));
    await bob.join(roomCode);

    final room = router.rooms.values.first;

    bob.markReady(isReady: true);
    expect(alice.gameStarted, completes);
    expect(bob.gameStarted, completes);
    expect(room.hasStarted, isFalse);

    await alice.socket.dispose();
    await alice.socket.init();
    await alice.join(roomCode);
    expect(alice.socket.roomCode, roomCode);

    alice.markReady(isReady: true);
    await Future<void>.delayed(Duration.zero);
    expect(room.hasStarted, isTrue);
  });
});
