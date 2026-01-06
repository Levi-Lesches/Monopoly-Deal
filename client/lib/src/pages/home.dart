import "package:flutter/material.dart";
import "package:mdeal/models.dart";

import "package:mdeal/widgets.dart";

/// The home page.
class HomePage extends ReusableReactiveWidget<HomeModel> {
  HomePage() : super(models.game);

  @override
  Widget build(BuildContext context, HomeModel model) => Scaffold(
    appBar: AppBar(title: const Text("Counter")),
    floatingActionButton: FloatingActionButton(
      onPressed: model.restart,
      child: const Icon(Icons.restart_alt),
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView(
              children: [
                if (model.errorMessage case final String error)
                  Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                for (final interruption in model.game.interruptions)
                  Text(interruption.toString(), textAlign: TextAlign.center),
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
                  CardWidget(
                    card,
                    // onSelected: model.choice2 is CardChoice
                      // ? () => model.cards.choose(card) : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
