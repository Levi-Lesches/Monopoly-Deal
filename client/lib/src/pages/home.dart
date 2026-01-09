import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";

import "package:mdeal/widgets.dart";

/// The home page.
class HomePage extends ReusableReactiveWidget<HomeModel> {
  HomePage() : super(models.game);

  @override
  Widget build(BuildContext context, HomeModel model) => Scaffold(
    appBar: AppBar(title: Text("${model.player}'s Game")),
    floatingActionButton: FloatingActionButton(
      child: const Text("Cancel"),
      onPressed: () => model.cancelChoice(),
    ),
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
                      Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
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
                    for (final (index, player) in model.game.allPlayers.indexed) ...[
                      PlayerWidget(
                        player: player,
                        playerIndex: index,
                      ),
                      const Divider(),
                    ],
                  ],
                ),
              ),
              const Divider(),
              if (model.player.name == model.game.currentPlayer)
              Row(children: [
                const Spacer(),
                if (model.canOrganize)
                  OutlinedButton(
                    onPressed: model.organize,
                    child: const Text("Re-arrange properties"),
                  ),
                const Spacer(),
              ],),
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
          )
        else if (model.game.winner case final Player player)
          Positioned.fill(
            child: Prompter(
              title: "$player won!",
              builder: (item) => Container(),
              choices: const [],
              onSelected: (_) { },
            ),
          )
        else if (model.choice case ConfirmCard(:final choices, :final color))
          Positioned.fill(
            child: Prompter(
              size: const Size(CardWidget.width, CardWidget.height),
              title: "Choose a card",
              canCancel: true,
              builder: (item) => CardWidget(item, fallbackColor: color),
              choices: choices,
              onSelected: model.cards.choose,
            ),
          ),
      ],
    ),
  );
}
