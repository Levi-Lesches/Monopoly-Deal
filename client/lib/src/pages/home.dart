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
    backgroundColor: model.stackNotifier.value == null && model.bankNotifier.value == null
      ? null : context.colorScheme.outlineVariant,
    appBar: AppBar(
      title: ListTile(title: Text("Room #${model.client.roomCode}"), subtitle: Text(model.player.name)),
      actions: [
        IconButton(
          icon: model.enableAnimations
            ? const Icon(Icons.pause_circle_outline)
            : const Icon(Icons.play_circle_outline),
          tooltip: "Toggle Animations",
          onPressed: model.toggleAnimations,
        ),
        IconButton(
          icon: models.audio.silent
            ? const Icon(Icons.volume_off)
            : const Icon(Icons.volume_up),
          tooltip: "Mute / Unmute",
          onPressed: models.audio.toggleMute,
        ),
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
        router.go(Routes.landing);
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
                            gkey: pickPileKey,
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
              if (model.expansionController.isExpanded)
                const SizedBox(height: 250)
              else
                const SizedBox(height: 50),
            ],
          ),
        ),
        Positioned.fill(child: buildPrompter(model.choice)),
        if (model.enableAnimations)
          AnimationLayer(),
        StackHintOverlay(),
        BankHintOverlay(),
        Positioned.fill(
          child: Column(
            children: [
              const Spacer(),
              ExpansionTile(
                controller: model.expansionController,
                title: Row(
                  children: [
                    const Text("Your cards"),
                    const Spacer(),
                    if (model.choice != null)
                      Text(buildPrompt(model.choice!), style: context.textTheme.bodyLarge),
                    const Spacer(),
                    if (model.player.name == model.game.currentPlayer && model.canOrganize)
                      OutlinedButton(
                        onPressed: model.organize,
                        child: const Text("Re-arrange properties"),
                      ),
                  ],
                ),
                backgroundColor: context.colorScheme.surfaceDim,
                collapsedBackgroundColor: context.colorScheme.surfaceDim,
                children: [
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
