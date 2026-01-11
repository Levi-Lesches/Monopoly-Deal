import "package:flutter/material.dart";
import "package:mdeal/data.dart";

export "package:go_router/go_router.dart";

export "src/widgets/generic/counter.dart";
export "src/widgets/generic/prompter.dart";
export "src/widgets/generic/reactive_widget.dart";
export "src/widgets/atomic/card.dart";
export "src/widgets/atomic/player.dart";
export "src/widgets/atomic/stack.dart";

/// Helpful methods on [BuildContext].
extension ContextUtils on BuildContext {
	/// Gets the app's color scheme.
	ColorScheme get colorScheme => Theme.of(this).colorScheme;

	/// Gets the app's text theme.
	TextTheme get textTheme => Theme.of(this).textTheme;

	/// Formats a date according to the user's locale.
	String formatDate(DateTime date) => MaterialLocalizations.of(this).formatCompactDate(date);

	/// Formats a time according to the user's locale.
	String formatTime(DateTime time) => MaterialLocalizations.of(this).formatTimeOfDay(TimeOfDay.fromDateTime(time));
}

extension PropertyColorUtils on PropertyColor {
  Color get flutterColor => switch (this) {
    .brown => Colors.brown,
    .lightBlue => Colors.lightBlue,
    .pink => Colors.pink,
    .orange => Colors.orange,
    .red => Colors.red,
    .yellow => Colors.yellow,
    .green => Colors.green,
    .darkBlue => Colors.blue.shade900,
    .railroads => Colors.grey.shade800,
    .utilities => Colors.teal,
  };
}

Color textColorFor(Color background) => switch(ThemeData.estimateBrightnessForColor(background)) {
  .dark => Colors.white,
  .light => Colors.black,
};
