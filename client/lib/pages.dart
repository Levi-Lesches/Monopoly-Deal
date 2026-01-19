import "package:flutter/foundation.dart";
import "package:go_router/go_router.dart";
export "package:go_router/go_router.dart";

import "src/pages/home.dart";
import "src/pages/lobby.dart";

/// Contains all the routes for this app.
class Routes {
  /// The route for the home page.
  static const game = "/game";
  static const lobby = "/lobby";
}

/// The router for the app.
final router = GoRouter(
  initialLocation: kDebugMode ? Routes.lobby : Routes.lobby,
  routes: [
    GoRoute(
      path: Routes.lobby,
      name: Routes.lobby,
      builder: (_, _) => LobbyPage(),
    ),
    GoRoute(
      path: Routes.game,
      name: Routes.game,
      builder: (_, state) => HomePage(),
    ),
  ],
);
