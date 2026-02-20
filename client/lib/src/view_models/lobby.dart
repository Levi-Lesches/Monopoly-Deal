import "dart:async";
import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

import "package:mdeal/models.dart";
import "package:mdeal/pages.dart";
import "package:mdeal/services.dart";
import "package:shared/shared.dart";

import "view_model.dart";

class LandingViewModel extends ViewModel {
  static final Uri defaultUri = kDebugMode
    ? Uri.parse("ws://localhost:8040")
    : Uri.parse("wss://deal.forgot-semicolon.com/socket/");

  // Page 0 = name/URI, 1=Room #, 2=Lobby
  final pageController = PageController();
  final usernameController = TextEditingController();
  final uriController = TextEditingController();
  final roomController = TextEditingController();

  @override
  Future<void> init() async {
    final uriString = services.prefs.uri;
    if (uriString != null) uri = Uri.parse(uriString);
    uriController.text = uri.toString();
    uriController.addListener(setUri);
    usernameController.text = services.prefs.name ?? "";
    usernameController.addListener(notifyListeners);
  }

  @override
  void dispose() {
    pageController.dispose();
    usernameController.dispose();
    uriController.dispose();
    roomController.dispose();
    unawaited(client?.dispose());
    unawaited(lobbySub?.cancel());
    unawaited(socketSub?.cancel());
    super.dispose();
  }

  Uri uri = defaultUri;
  String? uriError;

  String? _validateUrl(String text) {
    final result = Uri.tryParse(text);
    if (result == null) return "Not a valid URL";
    const allowedSchemes = {"ws", "wss"};
    if (!allowedSchemes.contains(result.scheme)) {
      return "URL must point to a websocket (ws:// or ws://)";
    }
    return null;
  }

  void setUri() {
    final text = uriController.text.nullIfEmpty;
    if (text == null) {
      uri = defaultUri;
      uriError = null;
      notifyListeners();
      return;
    }
    uriError = _validateUrl(text);
    notifyListeners();
    if (uriError == null) {
      uri = Uri.parse(text);
      notifyListeners();
    }
  }

  User? user;
  ClientSocket? socket;
  LobbyClient? client;
  StreamSubscription<void>? lobbySub;
  StreamSubscription<void>? socketSub;

  Future<void> gotoPage(int index) => pageController.animateToPage(
    index,
    curve: Curves.easeInQuart,
    duration: const Duration(milliseconds: 250),
  );

  bool get canConnect => usernameController.text.nullIfEmpty != null;
  Future<void> connect() async {
    final username = usernameController.text.nullIfEmpty;
    if (username == null) return;
    user = User(username);
    try {
      socket = ClientWebSocket(uri, user!);
      await socket!.init().timeout(const Duration(seconds: 2));
      socketSub = socket!.packets.listen((_) { }, onDone: backToName);
      services.prefs.uri = uri.toString();
      services.prefs.name = username;
      client = LobbyClient(socket!);
      unawaited(client!.gameStarted.then(_startGame));
      lobbySub = client!.lobbyUsers.listen(updateUsers);
      client!.init();
      errorText = null;
      await gotoPage(1);
    } catch (error) {
      errorText = kDebugMode
        ? "Error: $error"
        : "Something went wrong. Check your URL and try again";
    }
  }

  Future<void> backToName() async {
    user = null;
    await gotoPage(0);
    await client?.dispose();
    await socket?.dispose();
    await lobbySub?.cancel();
    await socketSub?.cancel();
    roomError = null;
    errorText = "The server closed unexpectedly";
    isReady = false;
    roomController.clear();
    uriError = null;
  }

  String? roomError;
  int get roomCode => socket?.roomCode ?? 0;
  int get unreadyCount => users.values.where((isReady) => !isReady).length;
  Future<void> joinRoom() async {
    final roomCode = int.tryParse(roomController.text);
    if (roomCode == null) {
      roomError = "Invalid number";
      notifyListeners();
      return;
    } else if (!roomCode.isBetween(0001, 9999)) {
      roomError = "0001-9999";
      notifyListeners();
      return;
    }
    try {
      await client!.join(roomCode);
      await gotoPage(2);
    } on MDealError catch (error) {
      roomError = error.toString();
      notifyListeners();
    } catch (error) {
      roomError = kDebugMode
        ? error.toString()
        : "Something went wrong";
      notifyListeners();
    }
  }

  Future<void> createRoom() async {
    try {
      await client!.join(null);
      await gotoPage(2);
    } on MDealError catch (error) {
      roomError = error.toString();
      notifyListeners();
    }
  }

  Map<String, bool> users = <String, bool>{};
  void updateUsers(Map<String, bool> value) {
    users = value;
    notifyListeners();
  }

  bool isReady = false;
  Future<void> toggleReady() async {
    isReady = !isReady;
    client!.markReady(isReady: isReady);
    notifyListeners();
  }

  Future<void> _startGame(_) async {
    await client?.dispose();
    final gameClient = MDealClient(client!.socket, socket!.roomCode);
    await models.startGame(gameClient);
    router.goNamed(Routes.game);
  }
}

extension on int {
  bool isBetween(int min, int max) => this > min && this < max;
}
