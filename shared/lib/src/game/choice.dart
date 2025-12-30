import "package:shared/data.dart";

// import "game.dart";

// sealed class PlayerAction {
//   final Player player;
//   const PlayerAction({required this.player});

//   bool isValid();
//   void handle(Game game);
// }

// class EndTurnAction extends PlayerAction {
//   const EndTurnAction({required super.player});
//   bool isValid() => true;
// }

// class BankAction extends PlayerAction {
//   final Card card;
//   const BankAction({required this.card, required super.player});

//   @override
//   bool isValid() => player.hasCardsInHand([card])
//     && card is! RainbowWildCard;

//   @override
//   void handle(Game game) {
//     player.hand.remove(card);
//     player.addMoney(card);
//   }
// }

// class


class TurnChoice {
  final Player player;
  final Card card;
  final bool isBanked;
  final PropertyColor? color;
  final Player? victim;
  final Card? toSteal;
  final Card? toGive;
  final DoubleTheRent? doubleTheRent;

  int get cardsUsed => doubleTheRent == null ? 1 : 2;

  const TurnChoice({
    required this.card,
    required this.player,
    this.isBanked = false,
    this.doubleTheRent,
    this.color,
    this.victim,
    this.toSteal,
    this.toGive,
  });

  bool isValid() => player.hasCardsInHand([card])
    && (toGive != null && player.hasCardsOnTable([toGive!]))
    && (doubleTheRent != null && player.hasCardsInHand([doubleTheRent!]));
}
