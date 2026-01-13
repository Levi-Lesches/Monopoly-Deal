import "dart:async";

import "package:flutter/widgets.dart";
import "package:mdeal/models.dart";
import "package:mdeal/pages.dart";
import "package:shared/network.dart";
import "package:shared/online.dart";
import "package:shared/utils.dart";

import "view_model.dart";

class LobbyViewModel extends ViewModel {
  static final addresses = <Uri>[
    Uri.parse("wss://deal.forgot-semicolon.com/socket/"),
    Uri.parse("ws://192.168.1.210:8040"),
    Uri.parse("ws://localhost:8040"),
  ];

  final nameController = TextEditingController();
  Map<String, bool> users = <String, bool>{};
  ClientSocket? socket;
  LobbyClient? client;
  Uri address = addresses.first;

  void updateAddress(Uri? value) {
    if (value == null) return;
    address = value;
    notifyListeners();
  }

  @override
  Future<void> init() async {
    nameController.addListener(notifyListeners);
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
  }

  bool hasJoined = false;
  Future<void> joinLobby() async {
    final name = this.name;
    if (name == null) return;
    final user = User(name);
    isLoading = true;

    final uri = address;
    socket = ClientWebSocket(uri, user);
    await socket!.init();

    client = LobbyClient(socket!);
    await client!.init();
    client!.lobbyUsers.listen(updateUsers);
    final result = await safelyAsync(() => client!.join());
    if (result == null) {isLoading = false; notifyListeners(); return; }
    hasJoined = result;
    unawaited(client!.gameStarted.then((_) => startGame()));
    isLoading = false;
    notifyListeners();
  }

  void updateUsers(Map<String, bool> value) {
    users = value;
    notifyListeners();
  }

  bool isReady = false;
  Future<void> toggleReady() async {
    isLoading = true;
    await client!.markReady(isReady: !isReady);
    isReady = !isReady;
    isLoading = false;
    notifyListeners();
  }

  Future<void> startGame() async {
    await client?.dispose();
    final gameClient = MDealClient(client!.socket);
    await gameClient.init();
    await models.startGame(gameClient);
    router.goNamed(Routes.game);
  }

  String? get name => nameController.text.trim().nullIfEmpty;
  bool get canJoin => name != null && !hasJoined;
  bool get canReady => hasJoined;
}
