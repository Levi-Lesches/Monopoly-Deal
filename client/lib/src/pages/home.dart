import "package:flutter/material.dart";

import "package:mdeal/view_models.dart";
import "package:mdeal/widgets.dart";

/// The home page.
class HomePage extends ReactiveWidget<HomeModel> {
  @override
  HomeModel createModel() => HomeModel();

  @override
  Widget build(BuildContext context, HomeModel model) => Scaffold(
    appBar: AppBar(title: const Text("Counter")),
    body: Center(
      child: GameWidget(model.game),
    ),
  );
}
