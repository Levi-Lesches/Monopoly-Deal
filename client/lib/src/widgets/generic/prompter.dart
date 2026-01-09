import "package:flutter/material.dart";
import "package:mdeal/widgets.dart";

typedef ItemBuilder<T> = Widget Function(T item);
class Prompter<T> extends StatelessWidget {
  final String title;
  final List<T> choices;
  final ItemBuilder<T> builder;
  final ValueChanged<T> onSelected;

  const Prompter({
    required this.title,
    required this.choices,
    required this.onSelected,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withAlpha(150),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.displaySmall
              ?.copyWith(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
            for (final item in choices)
              InkWell(
                onTap: () => onSelected(item),
                child: SizedBox(
                  width: 100, height: 100,
                  child: builder(item),
                ),
              ),
          ],)
        ],
      ),
    ),
  );
}
