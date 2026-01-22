import "package:flutter/material.dart";
import "package:mdeal/models.dart";
import "package:mdeal/widgets.dart";

class StackHintOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: models.game.stackNotifier,
    builder: (context, value, child) {
      if (value == null) return Container();
      final key = models.game.stackKeys[value.player.name]!;
      final position = getPosition(key);
      final offset = const Offset(16, -16)
        + (const Offset(CardWidget.width + 32, 0) * value.index.toDouble())
        + const Offset(0, -CardWidget.height);
      return Stack(
        children: [
          Positioned(
            left: (position + offset).dx,
            top: (position + offset).dy,
            child: Row(
              children: [
                for (final card in value.stack.allCards)
                  CardWidget(card),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class BankHintOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: models.game.bankNotifier,
    builder: (context, value, child) {
      if (value == null) return Container();
      final key = models.game.bankKeys[value.name]!;
      final position = getPosition(key) + const Offset(0, -CardWidget.height);
      return Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: Row(
              children: [
                for (final card in value.tableMoney)
                  CardWidget(card),
              ],
            ),
          ),
        ],
      );
    },
  );
}
