import "package:shared/network.dart";
import "package:shared/online.dart";

import "";
export "src/models/home.dart";
export "src/models/model.dart";

/// A [DataModel] to manage all other data models.
class Models extends DataModel {
	/// Prevents other instances of this class from being created.
	Models._();

  // List your models here
  HomeModel game = HomeModel(MDealClient(UdpClientSocket(User("test"), port: 9000)));

	/// A list of all models to manage.
	List<DataModel> get models => [game];

	@override
	Future<void> init() async {
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
    game = HomeModel(client);
    await game.init();
  }
}

/// The global data model singleton.
final models = Models._();
