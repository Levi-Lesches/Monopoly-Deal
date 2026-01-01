import "package:flutter/material.dart";
import "package:mdeal/data.dart";

class CardWidget extends StatelessWidget {
  final MCard card;

  const CardWidget(this.card);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    width: 100,
    child: Material(
      child: Text(card.name),
    ),
  );
}
