/// Defines and manages the different services used by the app.
library;

import "src/services/service.dart";
import "src/services/audio.dart";

/// A [Service] that manages all other services used by the app.
class Services extends Service {
	/// Prevents other instances of this class from being created.
	Services._();

  // Define your services here
  final audio = AudioService();

	/// The different services to initialize, in this order.
	List<Service> get services => [audio];

	@override
	Future<void> init() async {
		for (final service in services) {
      await service.init();
    }
	}
}

/// The global services object.
final services = Services._();
