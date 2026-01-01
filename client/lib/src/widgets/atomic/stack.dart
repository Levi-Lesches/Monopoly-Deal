import "package:flutter/material.dart";
import "package:mdeal/data.dart";

import "card.dart";

class StackWidget extends StatelessWidget {
  static const verticalSpacing = 20.0;

  final PropertyStack stack;
  const StackWidget(this.stack);

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final (index, card) in stack.allCards.indexed)
        Positioned(
          top: index * verticalSpacing,
          child: CardWidget(card),
        ),
    ],
  );
}
