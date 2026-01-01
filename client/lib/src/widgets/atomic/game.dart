import "package:flutter/material.dart";
import "package:mdeal/data.dart";

import "card.dart";
import "player.dart";

class GameWidget extends StatelessWidget {
  final GameState game;
  const GameWidget(this.game);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (index, otherPlayer) in game.otherPlayers.indexed) ...[
        PlayerWidget(player: otherPlayer, playerIndex: index + 1),
        const Divider(),
      ],
      PlayerWidget(player: game.player.hidden, playerIndex: 0),
      Row(
        children: [
          for (final card in game.player.hand)
            CardWidget(card),
        ],
      ),
    ],
  );
}
