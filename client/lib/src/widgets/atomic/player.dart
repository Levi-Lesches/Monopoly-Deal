import "package:flutter/material.dart";
import "package:mdeal/data.dart";

import "card.dart";
import "stack.dart";

class PlayerWidget extends StatelessWidget {
  static const colors = <Color>[
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.blueGrey,
  ];

  final int playerIndex;
  final HiddenPlayer player;
  const PlayerWidget({
    required this.player,
    required this.playerIndex,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 200,
        child: ListTile(
          title: Text(player.name),
          subtitle: Text("Net Worth: \$${player.netWorth}"),
          leading: CircleAvatar(
              backgroundColor: colors[playerIndex],
              child: const Icon(Icons.person),
            ),
        ),
      ),
      const SizedBox(width: 12),
      CardWidget(player.tableMoney.last),
      for (final stack in player.stacks)
        if (stack.isNotEmpty)
          StackWidget(stack),
    ],
  );
}
