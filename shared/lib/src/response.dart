import "card.dart";
import "deck.dart";
import "player.dart";

sealed class Response {
  final Player player;
  const Response({required this.player});
}

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

class PaymentResponse extends Response {
  /* TODO: House and hotels become banked */
  final List<Card> cards;
  const PaymentResponse({
    required this.cards,
    required super.player,
  });

  bool isValid(int amount) {
    if (!player.hasCardsOnTable(cards)) return false;
    return cards.every((card) => card.value > 0)
      && player.netWorth < amount
        ? cards.length == player.cardsWithValue.length
        : cards.totalValue >= amount;
  }
}

class JustSayNoResponse extends Response {
  final JustSayNo justSayNo;
  const JustSayNoResponse({
    required this.justSayNo,
    required super.player,
  });

  bool isValid() => player.hasCardsInHand([justSayNo]);
}

class AcceptedResponse extends Response {
  const AcceptedResponse({required super.player});
}

class ColorResponse extends Response {
  final PropertyColor color;
  const ColorResponse({
    required this.color,
    required super.player,
  });

  bool isValid(Card card) => switch (card) {
    WildPropertyCard(:final topColor, :final bottomColor) =>
      color == topColor || color == bottomColor,
    RainbowWildCard() => player.getStackWithRoom(color) != null,
    _ => false,
  };
}

class DiscardResponse extends Response {
  final List<Card> cards;
  const DiscardResponse({
    required this.cards,
    required super.player,
  });

  bool isValid(int amount) => player.hasCardsInHand(cards)
    && cards.length >= amount;
}
