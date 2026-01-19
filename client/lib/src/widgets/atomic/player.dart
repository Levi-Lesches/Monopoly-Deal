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
    Colors.red,
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
    if (!isPlayer || !isTurn) return null;
    return FilledButton(
      onPressed: model.game.interruptions.isEmpty ? models.game.endTurn : null,
      child: const Text("End Turn"),
    );
  }

  Widget? buildInterruptionTile(HomeModel model) => switch (model.game.interruption) {
    PaymentInterruption(:final amount, :final causedBy) => ListTile(
      leading: const Icon(Icons.attach_money, size: 36),
      title: Text("Pay $causedBy \$$amount"),
      subtitle: Text("Current value: ${model.cardChoices.totalValue}"),
      trailing: FilledButton(
        onPressed: model.canPay ? () => model.cards.confirmList() : null,
        child: const Text("Pay"),
      )
    ),
    DiscardInterruption(:final amount) => ListTile(
      leading: const Icon(Icons.delete_forever, size: 36),
      title: Text("Discard at least $amount card(s)"),
      subtitle: Text("Discarding: ${model.cards.values}"),
      trailing: FilledButton(
        onPressed: model.cards.values.length >= amount ? models.game.cards.confirmList : null,
        style: model.cards.values.isEmpty ? null : FilledButton.styleFrom(backgroundColor: Colors.red),
        child: model.cards.values.isEmpty ? const Text("End Turn") : const Text("Discard"),
      ),
    ),
    StealInterruption() => null,
    StealStackInterruption() => null,
    ChooseColorInterruption() => null,
    JustSayNoInterruption() => null,
    null => null,
  };

  Widget? buildOtherInterruptionTile(HomeModel model) => switch(model.game.interruptionFor(player)) {
    null => null,
    PaymentInterruption(:final amount, :final causedBy) => ListTile(
      leading: const Icon(Icons.paid, size: 36,),
      title: Text("Needs to pay $causedBy \$$amount"),
    ),
    StealInterruption(:final toGiveName) => ListTile(
      leading: toGiveName != null
        ? const Icon(Icons.swap_horizontal_circle, size: 36,)
        : const Icon(Icons.error, size: 36),
        title: Text(model.game.interruptionFor(player)!.toString()),
    ),
    StealStackInterruption(:final causedBy, :final color) => ListTile(
      leading: const Icon(Icons.error, size: 36),
      title: Text("$causedBy wants to steal the $color set"),
    ),
    ChooseColorInterruption() => const ListTile(
      leading: Icon(Icons.color_lens, size: 36),
      title: Text("Picking a color..."),
    ),
    DiscardInterruption(:final amount) => ListTile(
      leading: const Icon(Icons.delete_forever, size: 36),
      title: Text("Needs to discard at least $amount card(s)"),
    ),
    JustSayNoInterruption() => const ListTile(
      leading: Icon(Icons.block, size: 36),
      title: Text("Got blocked by a just say no!"),
    ),
  };

  bool get canChoose => model.choice is PlayerChoice && !isPlayer;

  @override
  Widget build(BuildContext context, HomeModel model) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        spacing: 12,
        children: [
          IntrinsicWidth(
            child: ListTile(
              tileColor: canChoose ? Colors.blueGrey.withAlpha(100) : null,
              onTap: canChoose ? () => model.players.choose(player) : null,
              leading: CircleAvatar(
                key: model.playerKeys[player.name],
                radius: isTurn ? 24 : 18,
                backgroundColor: colors[playerIndex],
                child: const Icon(Icons.person),
              ),
              title: Text(
                player.name,
                style: isTurn ? context.textTheme.titleLarge : null,
              ),
              subtitle: Text("Net Worth: \$${player.netWorth}"),
            ),
          ),
          const Spacer(),
          CounterWidget(count: player.handCount, max: 7, label: "Cards"),
          const Spacer(),
          CounterWidget(count: player.numSets, max: 3, label: "Sets"),
          const SizedBox(width: 12),
        ],
      ),

      if (isTurn && !model.game.isDiscarding)
        ListTile(
          leading: const Icon(Icons.pending, size: 36,),
          title: Text("It's $player's turn", style: context.textTheme.bodyLarge),
          subtitle: CounterWidget(count: model.game.turnsUsed, max: 3),
          trailing: getTrailingButton(context, model),
        ),

      if (isPlayer)
        ?buildInterruptionTile(model)
      else
        ?buildOtherInterruptionTile(model),

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
                  const EmptyCardWidget(),
                Positioned.fill(
                  child: InkWell(
                    onTap: canBank ? model.toggleBank : null,
                    child: Container(
                      color: Colors.blueGrey
                        .withAlpha(isPlayer && model.isBanking ? 255 : 120),
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        "BANK: \$${player.tableMoney.totalValue}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                if (canBank)
                  const Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text("PRESS TO BANK", style: TextStyle(color: Colors.white),),
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
      PropertyChoice(:final chooseOwn) when chooseOwn && isPlayer => [
        for (final stack in player.tableStacks)
          for (final card in stack.cards)
              CardWidget(card),
      ],
      PropertyChoice(:final chooseOthers) when !isPlayer && chooseOthers => [
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
