import "package:flutter/foundation.dart";
import "package:mdeal/data.dart";

class StackHint {
  final Player player;
  final PropertyStack stack;
  final int index;

  const StackHint({
    required this.player,
    required this.index,
    required this.stack,
  });
}

mixin HintsModel on ChangeNotifier {
  final stackNotifier = ValueNotifier<StackHint?>(null);
  final bankNotifier = ValueNotifier<Player?>(null);

  void showBankHint(Player player) {
    if (player.tableMoney.isEmpty) return;
    bankNotifier.value = player;
  }

  void showStackHint(StackHint hint) {
    if (hint.stack.isEmpty || hint.stack.cards.length == 1) return;
    stackNotifier.value = hint;
  }

  void clearHint() {
    stackNotifier.value = null;
    bankNotifier.value = null;
  }
}
