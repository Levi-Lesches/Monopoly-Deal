import "package:shared/data.dart";

sealed class InterruptionResponse {
  final Player player;
  const InterruptionResponse({required this.player});
}

class PaymentResponse extends InterruptionResponse {
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

class JustSayNoResponse extends InterruptionResponse {
  final JustSayNo justSayNo;
  const JustSayNoResponse({
    required this.justSayNo,
    required super.player,
  });

  bool isValid() => player.hasCardsInHand([justSayNo]);
}

class AcceptedResponse extends InterruptionResponse {
  const AcceptedResponse({required super.player});
}

class ColorResponse extends InterruptionResponse {
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

class DiscardResponse extends InterruptionResponse {
  final List<Card> cards;
  const DiscardResponse({
    required this.cards,
    required super.player,
  });

  bool isValid(int amount) => player.hasCardsInHand(cards)
    && cards.length >= amount;
}
