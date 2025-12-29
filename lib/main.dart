import "package:flutter/material.dart";

import "package:mdeal/models.dart";
import "package:mdeal/pages.dart";
import "package:mdeal/services.dart";

Future<void> main() async {
  await services.init();
  await models.init();
  await models.initFromOthers();
  runApp(const MdealApp());
}

/// The main app widget.
class MdealApp extends StatelessWidget {
  /// A const constructor.
  const MdealApp();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: "Flutter Demo",
    theme: ThemeData(
      useMaterial3: true,
    ),
    routerConfig: router,
  );
}
