import "";
export "src/models/home.dart";
export "src/models/model.dart";

/// A [DataModel] to manage all other data models.
class Models extends DataModel {
	/// Prevents other instances of this class from being created.
	Models._();

  // List your models here
  final game = HomeModel();

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
}

/// The global data model singleton.
final models = Models._();
