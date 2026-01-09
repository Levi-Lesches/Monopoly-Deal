import "dart:async";

import "package:flutter/widgets.dart";
import "package:mdeal/models.dart";
import "package:mdeal/pages.dart";
import "package:shared/network.dart";
import "package:shared/online.dart";
import "package:shared/utils.dart";

import "view_model.dart";

class LobbyViewModel extends ViewModel {
  final nameController = TextEditingController();
  UdpClientSocket? socket;
  LobbyClient? client;

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
    socket = UdpClientSocket(user, port: 0);
    await socket!.init();
    client = LobbyClient(socket!);
    await client!.init();
    hasJoined = await client!.join();
    unawaited(client!.gameStarted.then((_) => startGame()));
    isLoading = false;
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

  String? get name => nameController.text.nullIfEmpty;
  bool get canJoin => name != null && !hasJoined;
  bool get canReady => hasJoined;
}
