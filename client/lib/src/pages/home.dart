import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/pages.dart";

import "package:mdeal/widgets.dart";

/// The home page.
class HomePage extends ReusableReactiveWidget<HomeModel> {
  HomePage() : super(models.game);

  @override
  bool get shouldDispose => true;

  String buildPrompt(Choice<void> choice) => switch(choice) {
    PlayerChoice() => "Choose a player",
    CardChoice(:final message) => message,
    PropertyChoice() => "Choose a property",
    StackChoice() => "Choose a stack",
    ColorChoice() => "Choose a color",
    BoolChoice() => "Make a choice",
    MoneyChoice() => "Make a payment",
    ConfirmCard() => "Choose a property in that stack",
  };

  @override
  Widget build(BuildContext context, HomeModel model) => Scaffold(
    appBar: AppBar(
      title: Text("${model.player}'s Game"),
      actions: [
        IconButton(
          icon: const Icon(Icons.restore),
          tooltip: "Cancel / Restore",
          onPressed: () => model.cancelChoice(),
        ),
      ],
    ),
    floatingActionButtonLocation: .centerFloat,
    floatingActionButton: model.game.winner == null ? null : FloatingActionButton.extended(
      label: const Text("New game"),
      icon: const Icon(Icons.replay),
      onPressed: () async {
        router.go(Routes.lobby);
        await models.resetGame();
      },
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
                      height: CardWidget.height,
                      child: Row(
                        mainAxisSize: .min,
                        spacing: 8,
                        children: [
                          const SizedBox(width: 8),
                          EmptyCardWidget(
                            text: "${model.game.numCards}\nCards Left",
                            color: Colors.grey.shade800,
                          ),
                          if (model.game.discarded case final MCard card)
                            CardWidget(card)
                          else
                            const EmptyCardWidget(),
                          Expanded(
                            child: ListView(
                              children: [
                                for (final message in model.game.log)
                                  Text(message, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
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
              if (model.choice != null)
                Text(buildPrompt(model.choice!), style: context.textTheme.bodyLarge),
              const SizedBox(height: 8),
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
        Positioned.fill(child: buildPrompter(model.choice)),
        if (model.game.winner case final Player player)
          if (model.winnerPopup) Positioned.fill(
            child: Prompter(
              title: "$player won!",
              builder: (item) => Container(),
              canCancel: true,
              choices: const [],
              onSelected: (_) { },
            ),
          ),
      ],
    ),
  );

  Widget buildPrompter(Choice<void>? choice) => switch (choice) {
    ColorChoice(:final choices) => Prompter(
      title: "Choose a color",
      choices: choices,
      onSelected: model.colors.choose,
      builder: (item) => ColoredBox(color: item.flutterColor),
      ),
    BoolChoice(:final choices, :final title) => Prompter(
      title: title,
      choices: choices,
      onSelected: model.confirmations.choose,
      builder: (item) => item
        ? const Icon(Icons.check_box, size: 64, color: Colors.green)
        : const Icon(Icons.cancel, size: 64, color: Colors.red),
    ),
    ConfirmCard(:final choices, :final color) => Prompter(
      size: const Size(CardWidget.width, CardWidget.height),
      title: "Choose a card",
      canCancel: true,
      builder: (item) => CardWidget(item, fallbackColor: color),
      choices: choices,
      onSelected: model.cards.choose,
    ),
    null => Container(),
    CardChoice() => Container(),
    PropertyChoice() => Container(),
    StackChoice() => Container(),
    PlayerChoice() => Container(),
    MoneyChoice() => Container(),
  };
}
