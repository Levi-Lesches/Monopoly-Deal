import "package:flutter/foundation.dart";
import "package:go_router/go_router.dart";
export "package:go_router/go_router.dart";

import "src/pages/home.dart";
import "src/pages/lobby.dart";

/// Contains all the routes for this app.
class Routes {
  /// The route for the home page.
  static const game = "/game";
  static const landing = "/";
}

/// The router for the app.
final router = GoRouter(
  initialLocation: kDebugMode ? Routes.game : Routes.landing,
  routes: [
    GoRoute(
      path: Routes.landing,
      name: Routes.landing,
      builder: (_, _) => LandingPage(),
    ),
    GoRoute(
      path: Routes.game,
      name: Routes.game,
      builder: (_, state) => HomePage(),
    ),
  ],
);
