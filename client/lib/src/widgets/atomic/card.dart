import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/widgets.dart";

class CardWidget extends ReusableReactiveWidget<HomeModel> {
  static const width = 100.0;
  static const height = 200.0;
  static const size = Size(width, height);

  static const colors = <Color>[
    Colors.blueGrey,
    Colors.yellow,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  final MCard card;
  final PropertyColor? fallbackColor;
  final GlobalKey? gkey;
  CardWidget(this.card, {this.gkey, this.fallbackColor}) :
    super(models.game, key: ValueKey(card.uuid));

  bool get canChoose {
    if (models.game.choice case CardChoice(:final choices)) {
      return choices.contains(card);
    } else if (models.game.choice case PropertyChoice(:final choices)) {
      if (card is PropertyLike && choices.contains(card)) return true;
    } else if (models.game.choice case MoneyChoice(:final choices)) {
      return choices.contains(card);
    }
    return false;
  }

  Border get border {
    if (models.game.cardChoices.contains(card)) {
      return Border.all(width: 3, color: Colors.red);
    } else if (canChoose) {
      return Border.all(width: 3);
    } else {
      return Border.all();
    }
  }

  Color get color {
    if (card case PropertyCard(:final color)) {
      return color.flutterColor;
    } else if (card is WildCard) {
      return fallbackColor?.flutterColor ?? Colors.white;
    } else if (card.value == 10) {
      return Colors.red;
    } else {
      return colors[card.value];
    }
  }

  @override
  Widget build(BuildContext context, HomeModel model) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: SizedBox.fromSize(
      key: gkey,
      size: size,
      child: Material(
        elevation: canChoose ? 16 : 24,
        color: color,
        shape: border,
        child: InkWell(
          onTap: canChoose ? () => models.game.cards.choose(card) : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: const Alignment(-0.8, -0.9),
                child: Text("\$${card.value}", style: TextStyle(color: textColorFor(color))),
              ),
              Text(
                card.name,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColorFor(color)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmptyCardWidget extends StatelessWidget {
  final String text;
  final Color? color;
  final GlobalKey? gkey;
  const EmptyCardWidget({this.text = "Empty", this.color, this.gkey});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: SizedBox.fromSize(
      key: gkey,
      size: CardWidget.size,
      child: Container(
        decoration: BoxDecoration(color: color, border: Border.all()),
        alignment: .center,
        child: Text(
          text,
          textAlign: .center,
          style: color == null ? null : TextStyle(color: textColorFor(color!))),
      ),
    ),
  );
}
