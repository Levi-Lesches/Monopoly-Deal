import "package:flutter/animation.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/services.dart";

class AudioModel extends DataModel {
  @override
  Future<void> init() async {
    // models.game.events.listen(handleEvent);
  }

  void handleEvent(GameEvent event) {

  }

  void playMoney() => services.audio.playAsset("money.mp3");

  static Duration get cardDelay => const Duration(milliseconds: 425);
  void playCard(int amount) => services.audio.playAsset(
    "card.mp3",
    stopAt: cardDelay * amount,
    volumeCurve: Curves.easeOutQuint,
  );

  void playSteal() => services.audio.playAsset("steal.mp3");
  void playNo() => services.audio.playAsset("no.mp3");
}
