import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/widgets.dart";

class PlayerWidget extends ReusableReactiveWidget<HomeModel> {
  static const colors = <Color>[
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.blueGrey,
  ];

  final int playerIndex;
  final HiddenPlayer player;
  PlayerWidget({
    required this.player,
    required this.playerIndex,
  }) : super(models.game);

  bool get isTurn => turnsRemaining != null;
  int? get turnsRemaining => models.game.turnsFor(player);
  bool get canEndTurn => models.game.canEndTurn;

  @override
  Widget build(BuildContext context, HomeModel model) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(children: [
        const SizedBox(width: 12),
        CircleAvatar(
          radius: isTurn ? 24 : 18,
          backgroundColor: colors[playerIndex],
          child: const Icon(Icons.person),
        ),
        const SizedBox(width: 12),
        Text(
          player.name,
          style: isTurn ? context.textTheme.titleLarge : null,
        ),
        const Spacer(),
        Text("Net Worth: \$${player.netWorth}"),
        const Spacer(),
        Text(
          "Cards: ${player.handCount}",
          style: player.handCount > 7 ? const TextStyle(color: Colors.red) : null,
        ),
        const Spacer(),
        if (turnsRemaining != null)
          if (turnsRemaining! > 0)
            Text("Turns Left: $turnsRemaining / 3")
          else
            FilledButton(
              onPressed: canEndTurn ? models.game.endTurn : null,
              child: const Text("End Turn"),
            )
        else if (model.choice == Choice.player)
          FilledButton(
            onPressed: () => model.players.choose(player),
            child: const Text("Choose"),
          ),
        const SizedBox(width: 12),
      ],),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (player.tableMoney.lastOrNull case final MCard card)
            CardWidget(card)
          else
            EmptyCardWidget(),
          for (final stack in player.stacks)
            if (stack.isNotEmpty)
              StackWidget(stack),
        ],
      ),
    ],
  );
}
