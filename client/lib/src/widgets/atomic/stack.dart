import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";

import "card.dart";

class StackWidget extends StatelessWidget {
  static const verticalSpacing = 20.0;

  final PropertyStack stack;
  final GlobalKey? gkey;
  const StackWidget(this.stack, {this.gkey});

  bool get canChoose {
    final choice2 = models.game.choice;
    if (choice2 case StackChoice(:final choices) when choices.contains(stack)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: CardWidget.width + 16,
    height: CardWidget.height + (verticalSpacing * stack.allCards.length),
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
