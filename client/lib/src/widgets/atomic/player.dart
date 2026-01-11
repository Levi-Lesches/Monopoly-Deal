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
  final Player player;
  PlayerWidget({
    required this.player,
    required this.playerIndex,
  }) : super(models.game);

  bool get isTurn => turnsRemaining != null;
  int? get turnsRemaining => models.game.turnsFor(player);
  bool get isPlayer => player.name == models.game.player.name;
  bool get canBank => isPlayer && isTurn && turnsRemaining! > 0 && models.game.choice is CardChoice;

  Widget? getTrailingButton(BuildContext context, HomeModel model) {
    if (isPlayer) {
      if (!isTurn) return null;
      final interruption = model.game.interruption;
      return FilledButton(
        onPressed: interruption == null ? models.game.endTurn : null,
        child: const Text("End Turn"),
      );
    } else if (model.choice is PlayerChoice) {
      return FilledButton(
        onPressed: () => model.players.choose(player),
        child: const Text("Choose"),
      );
    } else {
      return null;
    }
  }

  Widget? buildInterruptionTile(HomeModel model) => switch (model.game.interruption) {
    PaymentInterruption(:final amount, :final causedBy) => ListTile(
      leading: const Icon(Icons.info, size: 36),
      title: Text("Pay $causedBy \$$amount"),
      subtitle: Text("Current value: ${model.cardChoices.totalValue}"),
      trailing: FilledButton(
        onPressed: model.canPay ? () => model.cards.confirmList() : null,
        child: const Text("Pay"),
      )
    ),
    DiscardInterruption(:final amount) => ListTile(
      leading: const Icon(Icons.info, size: 36),
      title: Text("Discard $amount cards"),
      subtitle: Text("Discarding: ${model.cards.values}"),
      trailing: FilledButton(
        onPressed: model.cards.values.length >= amount ? models.game.cards.confirmList : null,
        style: model.cards.values.isEmpty ? null : FilledButton.styleFrom(backgroundColor: Colors.red),
        child: model.cards.values.isEmpty ? const Text("End Turn") : const Text("Discard"),
      ),
    ),
    StealInterruption() || StealStackInterruption() || ChooseColorInterruption() => null,
    null => null,
    // _ => null,
  };

  @override
  Widget build(BuildContext context, HomeModel model) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runAlignment: WrapAlignment.spaceAround,
        spacing: 12,
        children: [
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
          const SizedBox(width: 12),
          Text("Net Worth: \$${player.netWorth}"),
          const SizedBox(width: 12),
          Text("Sets: ${player.numSets}"),
          const SizedBox(width: 12),
          Text(
            "Cards: ${player.handCount}",
            style: player.handCount > 7 ? const TextStyle(color: Colors.red) : null,
          ),
          const SizedBox(width: 12),
          if (turnsRemaining != null && turnsRemaining! > 0)
            Text("Turns Left: $turnsRemaining / 3"),
            const SizedBox(width: 12),
          ?getTrailingButton(context, model),
          const SizedBox(width: 12),
        ],
      ),
      if (isPlayer)
        ?buildInterruptionTile(model),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 12,
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
              const SizedBox(
                height: CardWidget.height,
                child: VerticalDivider(),
              ),
              ...buildStacks(model),
            ],
          ),
        ),
      ),
    ],
  );

  List<Widget> buildStacks(HomeModel model) {
    final choice = model.choice;
    return switch (choice) {
      PropertyChoice() when isPlayer => [
        for (final stack in player.tableStacks)
          for (final card in stack.cards)
              CardWidget(card),
      ],
      PropertyChoice() => [
        for (final stack in player.tableStacks)
          if (stack.isSet)
            StackWidget(stack)
          else
            for (final card in stack.cards)
              CardWidget(card),
      ],
      MoneyChoice() when isPlayer => [
        for (final card in player.cardsWithValue)
          CardWidget(card),
      ],
      _ => [
        for (final stack in player.tableStacks)
          StackWidget(stack),
      ],
    };
  }
}
