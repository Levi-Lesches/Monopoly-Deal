import "dart:async";

import "package:flutter/foundation.dart";

/// A model to load and manage state needed by any piece of UI.
///
/// [init] is called right away it is *not* awaited. Use [isLoading] and
/// [errorText] to convey progress to the user. This allows the UI to load immediately.
abstract class ViewModel with ChangeNotifier {
  /// Calls [init] right away but does not await it.
  ViewModel() {
    unawaited(init());
  }

	/// Override this method to initializes any data needed by the model.
  Future<void> init() async {}

  /// Whether this model is currently loading data. Setting this updates the UI.
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Whether this model has encountered an error. Setting this updates the UI.
  String? _errorText;
  String? get errorText => _errorText;
  set errorText(String? value) {
    _errorText = value;
    notifyListeners();
  }

  /// Wether this model is still attached to a widget.
  bool _isMounted = true;

  @override
  void notifyListeners() {
    if (_isMounted) super.notifyListeners();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }
}

/// A model to build a value from the UI.
abstract class BuilderModel<T> extends ViewModel {
	/// The value being edited.
	T get value;

	/// Whether the [value] is ready to be accessed.
	bool get isReady;
}
