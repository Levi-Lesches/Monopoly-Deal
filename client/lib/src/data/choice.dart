import "package:mdeal/data.dart";

sealed class Choice<T> {
  final List<T> choices;
  final bool canCancel;
  Choice(this.choices, {this.canCancel = false});
}

class CardChoice extends Choice<MCard> {
  final String message;

  CardChoice.discard(GameState game) :
    message = "Choose cards to discard",
    super(game.player.hand);

  CardChoice.bank(GameState game) : message = "Choose a card to bank", super([
    for (final card in game.player.hand)
      if (card is! PropertyLike && card is! MoneyCard && card.value > 0)
        card,
  ]);

  CardChoice.play(GameState game) : message = "Choose a card to play", super([
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
  StackChoice.self(GameState game, {List<PropertyColor>? colors}) : super([
    for (final stack in game.player.stacks)
      if (stack.isNotEmpty && (colors == null || colors.contains(stack.color)))
        stack,
  ]);

  StackChoice.selfSets(GameState game, {bool withHouse = false}) : super([
    for (final stack in game.player.stacks)
      if (stack.isSet && (!withHouse || stack.house != null))
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
  ColorChoice(this.message, super.choices, {super.canCancel = true});
}

class BoolChoice extends Choice<bool> {
  final String title;
  BoolChoice(this.title, {List<bool> choices = const [true, false]}) : super(choices);
}

class MoneyChoice extends Choice<MCard> {
  MoneyChoice(GameState game) : super(game.player.cardsWithValue.toList());
}

class ConfirmCard extends Choice<MCard> {
  final PropertyColor color;
  ConfirmCard(super.choices, this.color);
}
