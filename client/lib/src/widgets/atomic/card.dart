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

  final MCard card;
  final PropertyColor? fallbackColor;
  CardWidget(this.card, {this.fallbackColor}) :
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

  Widget get child => Center(
    child: Text(
      card.name,
      textAlign: TextAlign.center,
      style: TextStyle(color: textColorFor(color)),
    ),
  );

  @override
  Widget build(BuildContext context, HomeModel model) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: SizedBox(
      height: height,
      width: width,
      child: Material(
        elevation: canChoose ? 16 : 24,
        color: color,
        shape: border,
        child: InkWell(
          onTap: canChoose ? () => models.game.cards.choose(card) : null,
          child: child,
        ),
      ),
    ),
  );
}

class EmptyCardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: SizedBox(
      height: CardWidget.height,
      width: CardWidget.width,
    ),
  );
}
