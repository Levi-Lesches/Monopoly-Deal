import "package:flutter/foundation.dart";

/// A model containing data needed throughout the app.
///
/// This model may need to be initialized, so [init] should be called before using it. This model
/// should also be held as a singleton in some global scope.
abstract class DataModel with ChangeNotifier {
	/// Loads any data needed by the model.
  ///
  /// This function must not depend on any other model.
	Future<void> init();

  /// Loads any data from other models.
  ///
  /// At this point, all models have run [init], so it is safe to use other models.
  Future<void> initFromOthers() async { }
}
