import "package:mdeal/data.dart";

import "";
export "src/models/home.dart";
export "src/models/model.dart";

/// A [DataModel] to manage all other data models.
class Models extends DataModel {
	/// Prevents other instances of this class from being created.
	Models._();

  // List your models here
  late HomeModel game;

	/// A list of all models to manage.
	List<DataModel> get models => [game];

	@override
	Future<void> init() async {
    final user = User("test1");
    final mockClient = MockGameClient(user);
    await mockClient.init();
    game = HomeModel(mockClient, mockClient.state);

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
    await client.requestState();
    final state = await client.gameUpdates.first;
    game = HomeModel(client, state);
    await game.init();
  }
}

/// The global data model singleton.
final models = Models._();
