import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";

import "package:mdeal/widgets.dart";

/// The home page.
class HomePage extends ReusableReactiveWidget<HomeModel> {
  HomePage() : super(models.game);

  @override
  Widget build(BuildContext context, HomeModel model) => Scaffold(
    appBar: AppBar(title: const Text("Counter")),
    body: Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (model.errorMessage case final String error)
                      Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        children: [
                          for (final message in model.game.log)
                            Text(message, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    const Divider(),
                    for (final (index, otherPlayer) in model.game.otherPlayers.indexed) ...[
                      PlayerWidget(
                        player: otherPlayer,
                        playerIndex: index + 1,
                      ),
                      const Divider(),
                    ],
                    PlayerWidget(
                      player: model.player.hidden,
                      playerIndex: 0,
                    ),
                  ],
                ),
              ),
              const Divider(),
              SizedBox(
                height: CardWidget.height,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final card in model.game.player.hand)
                      CardWidget(card),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (model.choice case ColorChoice(:final choices))
          Positioned.fill(
            child: Prompter(
              title: "Choose a color",
              choices: choices,
              onSelected: model.colors.choose,
              builder: (item) => ColoredBox(color: item.flutterColor),
            )
          )
        else if (model.choice case BoolChoice(:final choices, :final title))
          Positioned.fill(
            child: Prompter(
              title: title,
              choices: choices,
              onSelected: model.confirmations.choose,
              builder: (item) => item
                ? const Icon(Icons.check_box, size: 64, color: Colors.green)
                : const Icon(Icons.cancel, size: 64, color: Colors.red),
            ),
          ),
      ],
    ),
  );
}
