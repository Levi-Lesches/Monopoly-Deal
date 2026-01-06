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
  // final VoidCallback? onSelected;
  bool get isChoosing => models.game.choice2 is CardChoice;
  CardWidget(this.card) : super(models.game, key: ValueKey(card.uuid));

  bool get canChoose {
    if (models.game.choice2 case CardChoice(:final choices)) {
      return choices.contains(card);
    } else if (models.game.choice2 case PropertyChoice(:final choices)) {
      if (card is PropertyLike && choices.contains(card)) return true;
    }
    return false;
  }

  Border get border {
    if (models.game.choice2 case CardChoice(:final choices)) {
      if (models.game.toDiscard.contains(card)) {
        return Border.all(width: 3, color: Colors.red);
      } else if (choices.contains(card)) {
        return Border.all(width: 3);
      }
    }
    return Border.all();
  }

  Widget get child => Center(
    child: Text(card.name, textAlign: TextAlign.center),
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
