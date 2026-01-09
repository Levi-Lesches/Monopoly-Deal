import "package:mdeal/data.dart";

sealed class Choice<T> {
  final List<T> choices;
  Choice(this.choices);
}

class CardChoice extends Choice<MCard> {
  CardChoice.discard(GameState game) : super(game.player.hand);

  CardChoice.bank(GameState game) : super([
    for (final card in game.player.hand)
      if (card is! PropertyLike && card is! MoneyCard && card.value > 0)
        card,
  ]);

  CardChoice.play(GameState game) : super([
    for (final card in game.player.hand)
      if (game.canPlay(card))
        card
  ]);
}

class PropertyChoice extends Choice<PropertyLike> {
  PropertyChoice.self(GameState game) : super([
    for (final stack in game.player.stacks)
        ...stack.cards,
  ]);

  PropertyChoice.others(GameState game) : super([
    for (final player in game.otherPlayers)
      for (final stack in player.stacks)
        if (!stack.isSet)
          ...stack.cards,
  ]);
}

class StackChoice extends Choice<PropertyStack> {
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

  StackChoice.rainbowWild(GameState game) : super([
    for (final stack in game.player.stacks)
      if (stack.hasRoom)
        stack,
  ]);
}

class PlayerChoice extends Choice<Player> {
  PlayerChoice(GameState game) : super(game.otherPlayers);
}

class ColorChoice extends Choice<PropertyColor> {
  final String message;
  ColorChoice(this.message, super.choices);
}

class BoolChoice extends Choice<bool> {
  final String title;
  BoolChoice(this.title, {List<bool> choices = const [true, false]}) : super(choices);
}

class MoneyChoice extends Choice<MCard> {
  MoneyChoice(GameState game) : super(game.player.cardsWithValue.toList());
}
