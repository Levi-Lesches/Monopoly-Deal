import "package:mdeal/data.dart";

sealed class Choice2<T> {
  final List<T> choices;
  Choice2(this.choices);
}

class CardChoice extends Choice2<MCard> {
  CardChoice.discard(GameState game) : super(game.player.hand);

  CardChoice.bank(GameState game) : super([
    for (final card in game.player.hand)
      if (card.value > 0)
        card,
  ]);

  CardChoice.play(GameState game) : super([
    for (final card in game.player.hand)
      if (game.canPlay(card))
        card
  ]);
}

class PropertyChoice extends Choice2<PropertyLike> {
  PropertyChoice.self(GameState game) : super([
    for (final stack in game.player.stacks)
      if (!stack.isSet)
        ...stack.cards,
  ]);

  PropertyChoice.others(GameState game) : super([
    for (final player in game.otherPlayers)
      for (final stack in player.stacks)
        if (!stack.isSet)
          ...stack.cards,
  ]);
}

class StackChoice extends Choice2<PropertyStack> {
  StackChoice.rent(GameState game, {List<PropertyColor>? colors}) : super([
    for (final stack in game.player.stacks)
      if (stack.isNotEmpty && (colors == null || colors.contains(stack.color)))
        stack,
  ]);

  StackChoice.selfSets(GameState game) : super([
    for (final stack in game.player.stacks)
      if (stack.isSet)
        stack,
  ]);

  StackChoice.others(GameState game) : super([
    for (final player in game.otherPlayers)
      for (final stack in player.stacks)
        if (stack.isSet)
          stack,
  ]);
}

class PlayerChoice extends Choice2<Player> {
  PlayerChoice(GameState game) : super(game.otherPlayers);
}

// class Choice<T> {
//   List<T> get choices;
// }

// sealed class BankCardChoice extends Choice<MCard> {
//   bool isValid(RevealedPlayer player, MCard card) =>
//     player.hasCardsInHand([card])
//     && card.value > 0;
// }

// sealed class DiscardChoice extends Choice<MCard> {
//   bool isValid(RevealedPlayer player, MCard card) =>
// }
