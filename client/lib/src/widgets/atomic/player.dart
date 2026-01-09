import "package:collection/collection.dart";
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
  bool get isPlayer => player.name == models.game.player.name;
  bool get canBank => isPlayer && isTurn && turnsRemaining! > 0;

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
        if (turnsRemaining != null && turnsRemaining! > 0)
          Text("Turns Left: $turnsRemaining / 3"),
        const Spacer(),
        if (isPlayer && isTurn)
          if (model.toDiscard.isEmpty) FilledButton(
            onPressed: canEndTurn ? models.game.endTurn : null,
            child: const Text("End Turn"),
          ) else FilledButton(
            onPressed: canEndTurn ? models.game.endTurn : null,
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Discard"),
          )
        else if (model.choice2 is PlayerChoice && !isPlayer)
          FilledButton(
            onPressed: () => model.players.choose(player),
            child: const Text("Choose"),
          ),
        const SizedBox(width: 12),
      ],),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Stack(children: [
                if (player.tableMoney.lastOrNull case final MCard card)
                  CardWidget(card)
                else
                  EmptyCardWidget(),
                Positioned.fill(
                  child: InkWell(
                    onTap: canBank ? model.toggleBank : null,
                    child: Container(
                      color: Colors.blueGrey
                        .withAlpha(isPlayer && model.isBanking ? 255 : 100),
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        "BANK: \$${player.tableMoney.totalValue}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],),
              const SizedBox(width: 8),
              const SizedBox(
                height: CardWidget.height,
                child: VerticalDivider(),
              ),
              const SizedBox(width: 8),
              ...buildStacks(model),
            ],
          ),
        ),
      ),
    ],
  );

  List<Widget> buildStacks(HomeModel model) {
    final choice = model.choice2;
    return switch (choice) {
      PlayerChoice() || CardChoice() || StackChoice() || null => [
        for (final stack in player.tableStacks)
          StackWidget(stack),
      ],
      PropertyChoice() => [
        for (final stack in player.tableStacks)
          if (stack.isSet)
            StackWidget(stack)
          else
            for (final card in stack.cards)
              CardWidget(card),
      ],
    };
  }

  // bool canChooseProperty(HomeModel model) => switch(model.choice2) {
  //   null => false,
  //   PropertyChoice() =>
  // }
}
