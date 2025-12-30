import "package:flutter/material.dart";

abstract class ReactiveWidgetInterface<T extends ChangeNotifier> extends StatefulWidget {
  const ReactiveWidgetInterface();

  /// A function to create or find the model. This function will only be called once.
  T createModel();

  /// Whether the view model should be disposed or not.
  bool get shouldDispose;

  /// Builds the UI according to the state in [model].
	Widget build(BuildContext context, T model);

  @override
	ReactiveWidgetState createState() => ReactiveWidgetState<T>();

  /// This function gives you an opportunity to update the view model when the widget updates.
  ///
  /// For more details, see [State.didUpdateWidget].
  void didUpdateWidget(covariant ReactiveWidgetInterface<T> oldWidget, T model) { }
}

/// A widget that creates, subscribes to, and disposes of a [ChangeNotifier].
abstract class ReactiveWidget<T extends ChangeNotifier> extends ReactiveWidgetInterface<T> {
	/// A const constructor.
	const ReactiveWidget();

  @override
	T createModel();

  @override
  bool get shouldDispose => true;
}

/// A [ReactiveWidget] that works with a reusable [ChangeNotifier].
abstract class ReusableReactiveWidget<T extends ChangeNotifier> extends ReactiveWidgetInterface<T> {
  /// The model to listen to.
  final T model;
  /// Creates a widget that listens to a view model.
  const ReusableReactiveWidget(this.model);

  @override
  T createModel() => model;

  @override
  bool get shouldDispose => false;
}

/// A state for [ReactiveWidget] that manages the [model].
class ReactiveWidgetState<T extends ChangeNotifier> extends State<ReactiveWidgetInterface<T>>{
	/// The model to listen to.
	late final T model;

	@override
	void initState() {
		super.initState();
		model = widget.createModel();
		model.addListener(listener);
	}

	@override
	void dispose() {
		model.removeListener(listener);
    if (widget.shouldDispose) model.dispose();
		super.dispose();
	}

  @override
  void didUpdateWidget(covariant ReactiveWidgetInterface<T> oldWidget) {
    widget.didUpdateWidget(oldWidget, model);
    super.didUpdateWidget(oldWidget);
  }

	/// Updates the UI when [model] updates.
	void listener() => setState(() {});

	@override
	Widget build(BuildContext context) => widget.build(context, model);
}
