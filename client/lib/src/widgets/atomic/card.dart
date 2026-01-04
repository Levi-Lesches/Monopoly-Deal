import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/widgets.dart";

class CardWidget extends ReusableReactiveWidget<HomeModel> {
  static const width = 100.0;
  static const height = 200.0;

  static const colors = <Color>[
    Colors.blueGrey,
    Colors.yellow,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  Color get color => card is PropertyCard || card is WildPropertyCard
    ? Colors.white
    : card.value == 10 ? Colors.red : colors[card.value];

  final MCard card;
  final VoidCallback? onSelected;
  CardWidget(this.card, {this.onSelected}) : super(models.game);

  Border get border => models.game.choice == Choice.card
    ? models.game.toDiscard.contains(card)
      ? Border.all(width: 3, color: Colors.red)
      : Border.all(width: 3)
    : Border.all();

  @override
  Widget build(BuildContext context, HomeModel model) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: SizedBox(
      height: height,
      width: width,
      child: Material(
        elevation: onSelected == null ? 16 : 24,
        color: color,
        shape: border,
        child: InkWell(
          onTap: onSelected,
          child: Center(
            child: Text(card.name, textAlign: TextAlign.center),
          ),
        ),
      ),
    ),
  );
}

class EmptyCardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: SizedBox(
      height: CardWidget.height,
      width: CardWidget.width,
      child: Material(
        elevation: 24,
        color: Colors.blueGrey,
        shape: Border.all(),
        child: const Center(
          child: Text("Money", textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}
