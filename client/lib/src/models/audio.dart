import "package:mdeal/models.dart";
import "package:mdeal/services.dart";

class AudioModel extends DataModel {
  bool get silent => services.audio.silent;

  @override
  Future<void> init() async {
  }

  void toggleMute() {
    services.audio.silent = !services.audio.silent;
    notifyListeners();
  }

  void playMoney() => services.audio.playAsset("money.mp3");

  static Duration get cardDelay => const Duration(milliseconds: 425);
  void playCard(int amount, {double speed = 1}) => services.audio.playAsset(
    "card.mp3",
    stopAt: cardDelay * amount,
    speed: speed,
    volumeCurve: null,
  );

  void playSteal() => services.audio.playAsset("steal.mp3");
  void playNo() => services.audio.playAsset("no.mp3");
}
