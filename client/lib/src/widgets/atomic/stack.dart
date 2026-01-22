import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";

import "card.dart";

class StackWidget extends StatelessWidget {
  static Size getSizeFor(PropertyStack stack) => Size(
    CardWidget.width + 16,
    CardWidget.height + (verticalSpacing * stack.allCards.length),
  );
  static const verticalSpacing = 20.0;

  final PropertyStack stack;
  final GlobalKey? gkey;
  final int index;
  final Player player;
  const StackWidget(this.stack, {required this.player, required this.index, this.gkey});

  bool get canChoose {
    final choice2 = models.game.choice;
    if (choice2 case StackChoice(:final choices) when choices.contains(stack)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: getSizeFor(stack),
    child: Stack(
      children: [
        if (stack.isSet)
          Positioned.fill(
            child: ColoredBox(color: Colors.green.withAlpha(150)),
          ),
        for (final (index, card) in stack.allCards.indexed)
          Positioned(
            top: index * verticalSpacing,
            child: CardWidget(card, fallbackColor: stack.color),
          ),
        if (canChoose)
          Positioned.fill(
            child: InkWell(
              onTap: () => models.game.stacks.choose(stack),
              child: ColoredBox(color: Colors.blueGrey.withAlpha(100)),
            ),
          ),
        Positioned.fill(
          child: GestureDetector(
            behavior: .translucent,
            onLongPress: () => models.game.showStackHint(
              StackHint(player: player, stack: stack, index: index),
            ),
            onLongPressEnd: (_) => models.game.clearHint(),
            onSecondaryTapDown: (_) => models.game.showStackHint(
              StackHint(player: player, stack: stack, index: index),
            ),
            onSecondaryTapUp: (_) => models.game.clearHint(),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 8,
          key: gkey,
          child: Container(
            alignment: Alignment.bottomCenter,
            color: Colors.black.withAlpha(100),
            height: 22,
            width: CardWidget.width,
            child: Text("RENT: \$${stack.rent}", style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}
