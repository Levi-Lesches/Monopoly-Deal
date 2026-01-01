import "package:mdeal/data.dart";

import "view_model.dart";

/// The view model for the home page.
class HomeModel extends ViewModel {
  final levi = RevealedPlayer("Levi");
  final david = RevealedPlayer("Levi");
  late final _game = Game([levi, david]);
  GameState get game => _game.getStateFor(levi);
}
