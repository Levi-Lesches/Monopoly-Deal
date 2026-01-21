import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/services.dart";

class AudioModel extends DataModel {
  @override
  Future<void> init() async {
    models.game.events.listen(handleEvent);
  }

  Future<void> handleEvent(GameEvent event) async {
    switch (event) {
      case BankEvent():
        await services.audio.playAsset("money.mp3");
      case _:
    }
  }
}
