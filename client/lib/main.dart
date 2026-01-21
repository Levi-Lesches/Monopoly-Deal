import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "package:mdeal/models.dart";
import "package:mdeal/pages.dart";
import "package:mdeal/services.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await services.init();
  await models.init();
  await models.initFromOthers();
  runApp(const MdealApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    // etc.
  };
}

/// The main app widget.
class MdealApp extends StatelessWidget {
  /// A const constructor.
  const MdealApp();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    scrollBehavior: MyCustomScrollBehavior(),
    title: "Monopoly Deal",
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
    ),
    routerConfig: router,
  );
}
