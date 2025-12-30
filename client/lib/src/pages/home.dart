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
      child: Column(
        children: [
          const Text("You have pressed the button this many times"),
          Text(model.count.toString()),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: model.increment,
      child: const Icon(Icons.add),
    ),
  );
}
