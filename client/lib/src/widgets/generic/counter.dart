import "dart:math" as math;

import "package:flutter/material.dart";
import "package:mdeal/widgets.dart";
import "package:shared/utils.dart";

class CounterWidget extends StatelessWidget {
  final String? label;
  final int count;
  final int max;
  final double size;
  const CounterWidget({
    required this.count,
    required this.max,
    this.label,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    spacing: 8,
    children: [
      if (label != null)
        Text(label!, style: context.textTheme.bodyLarge),
      Row(
        spacing: 4,
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          for (final i in range(math.max(count, max)))
            if (i > (max - 1))
              Icon(Icons.circle, size: size, color: Colors.red)
            else if (i < count)
              Icon(Icons.circle, size: size, color: Colors.black)
            else
              Icon(Icons.circle_outlined, size: size, color: Colors.black),
        ],
      ),
    ],
  );
}
