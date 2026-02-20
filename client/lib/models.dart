import "dart:async";

import "package:mdeal/data.dart";

import "";
export "src/models/home.dart";
export "src/models/model.dart";
export "src/models/audio.dart";

/// A [DataModel] to manage all other data models.
class Models extends DataModel {
	/// Prevents other instances of this class from being created.
	Models._();

  // List your models here
  late HomeModel game;
  final audio = AudioModel();

	/// A list of all models to manage.
	List<DataModel> get models => [game, audio];

  Future<void> resetGame() async {
    final user = User("test1");
    final mockClient = MockGameClient(user);
    game = HomeModel(mockClient, mockClient.state);
    await audio.init();
  }

	@override
	Future<void> init() async {
    await resetGame();
		for (final model in models) {
      await model.init();
    }
	}

  @override
  Future<void> initFromOthers() async {
    for (final model in models) {
      await model.initFromOthers();
    }
  }

  Future<void> startGame(MDealClient client) async {
    client.requestState();
    final state = await client.gameUpdates.first
      .timeout(const Duration(seconds: 1));
    game = HomeModel(client, state);
    await game.init();
  }
}

/// The global data model singleton.
final models = Models._();
