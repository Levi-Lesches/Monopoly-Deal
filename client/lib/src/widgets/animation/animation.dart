import "dart:async";

import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/widgets.dart";

final GlobalKey discardPileKey = GlobalKey();
final GlobalKey listViewKey = GlobalKey();

class Animated {
  final Widget widget;
  final GlobalKey start;
  final Offset moveBy;

  Animated({
    required this.widget,
    required this.start,
    required this.moveBy,
  });
}

class AnimationLayer extends StatefulWidget {
  @override
  AnimationLayerState createState() => AnimationLayerState();
}

class AnimationLayerState extends State<AnimationLayer> with SingleTickerProviderStateMixin {
  Animated? animated;
  late AnimationController controller;

  StreamSubscription<void>? sub;
  @override
  void initState() {
    super.initState();
    sub = models.game.events.listen(animate);
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    controller.addStatusListener(onDone);
  }

  void onDone(AnimationStatus status) {
    switch(status) {
      case AnimationStatus.completed:
        stop();
      case _:
    }
  }

  @override
  void dispose() {
    unawaited(sub?.cancel());
    controller.dispose();
    super.dispose();
  }

  void stop() {
    setState(() => animated = null);
    controller.reset();
  }

  void animate(GameEvent event) {
    stop();
    switch (event) {
      case BankEvent(:final player, :final value):
        setState(() => animated = Animated(
          moveBy: const Offset(0, -100),
          start: models.game.bankKeys[player]!,
          widget: Text("\$$value", style: context.textTheme.displaySmall),
        ));
      case _:
    }
    unawaited(controller.forward());
  }

  Offset getPosition() {
    final box = animated!.start.currentContext?.findRenderObject() as RenderBox?;
    final scrollable = listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || scrollable == null) return Offset.zero;
    return box.localToGlobal(Offset.zero, ancestor: scrollable); //this is global position
  }

  @override
  Widget build(BuildContext context) => animated == null ? Container() : AnimatedBuilder(
    animation: controller,
    builder: (context, child) => Positioned(
      left: getPosition().dx + animated!.moveBy.dx*controller.value,
      top: getPosition().dy + animated!.moveBy.dy*controller.value,
      child: Opacity(
        opacity: Tween<double>(begin: 1, end: 0).evaluate(controller),
        child: SizedBox.fromSize(
          size: CardWidget.size,
          child: Center(child: animated!.widget),
        ),
      ),
    ),
  );
}
