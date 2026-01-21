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
          onPressed: () {
            final client = model.client;
            if (client is MockGameClient) client.debug();
            model.cancelChoice();
          }
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
                  key: listViewKey,
                  controller: model.scrollController,
                  children: [
                    if (model.errorMessage case final String error)
                      Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                    SizedBox(
                      height: CardWidget.height,
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          EmptyCardWidget(
                            text: "${model.game.numCards}\nCards Left",
                            color: Colors.grey.shade800,
                          ),
                          if (model.game.discarded case final MCard card)
                            Container(key: discardPileKey, child: CardWidget(card))
                          else
                            EmptyCardWidget(text: "Discard\nPile", gkey: discardPileKey),
                          Expanded(
                            child: ListView(
                              reverse: true,
                              children: [
                                for (final message in model.game.log)
                                  Text("- $message", style: context.textTheme.bodySmall, textAlign: TextAlign.start),
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
              ExpansionTile(
                initiallyExpanded: model.game.currentPlayer == model.player.name,
                controller: model.expansionController,
                title: const Text("Your cards"),
                children: [
                  if (model.choice != null)
                    Text(buildPrompt(model.choice!), style: context.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  if (model.player.name == model.game.currentPlayer && model.canOrganize)
                    OutlinedButton(
                      onPressed: model.organize,
                      child: const Text("Re-arrange properties"),
                    ),
                  SizedBox(
                    height: CardWidget.height,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final card in model.game.player.hand)
                          CardWidget(card, gkey: model.getCardKey(card)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned.fill(child: buildPrompter(model.choice)),
        AnimationLayer(),
        if (model.game.winner case final Player player)
          if (model.winnerPopup) Positioned.fill(
            child: Prompter(
              title: "$player won!",
              builder: (item) => Container(),
              canCancel: .cancel,
              choices: const [],
              onSelected: (_) { },
            ),
          ),
      ],
    ),
  );

  Widget buildPrompter(Choice<void>? choice) => switch (choice) {
    ColorChoice(:final choices, :final canCancel) => Prompter(
      title: "Choose a color",
      choices: choices,
      onSelected: model.colors.choose,
      canCancel: canCancel ? .reload : .none,
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
      canCancel: .reload,
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
