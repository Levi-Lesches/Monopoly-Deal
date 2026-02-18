import "package:shared/shared.dart";
import "package:test/test.dart";

import "mock_sockets.dart";

Future<(MockServerSocket, MockClientSocket, MockClientSocket)> initSockets() async {
  final server = MockServerSocket();
  final alice = MockClientSocket(aliceUser, server);
  final bob = MockClientSocket(bobUser, server);
  await server.init();
  addTearDown(() async {
    await server.dispose();
    await alice.dispose();
    await bob.dispose();
  });
  return (server, alice, bob);
}

Future<(Router, LobbyClient, LobbyClient)> initLobbies() async {
  final (server, aliceSocket, bobSocket) = await initSockets();
  final router = Router(server);
  final alice = LobbyClient(aliceSocket);
  final bob = LobbyClient(bobSocket);
  router.init();
  alice.init();
  bob.init();
  addTearDown(() async {
    await router.dispose();
    await alice.dispose();
    await bob.dispose();
  });
  return (router, alice, bob);
}

void main() => group("[rooms]", () {
  test("cannot join a room that doesn't exist", () async {
    final (router, alice, bob) = await initLobbies();
    expect(alice.join(100), throwsA(isA<GameError>()));
    alice.gameStarted.ignore();
    bob.gameStarted.ignore();
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
    alice.gameStarted.ignore();
    bob.gameStarted.ignore();
  });

  test("a second player can join an open room", () async {
    final (router, alice, bob) = await initLobbies();
    final roomCode = await alice.join(null);
    expect(roomCode, isNot(0));
    final bobCode = await bob.join(roomCode);
    expect(bobCode, roomCode);
    alice.gameStarted.ignore();
    bob.gameStarted.ignore();
  });
});
