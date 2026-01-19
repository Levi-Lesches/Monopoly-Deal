import "dart:async";

import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/widgets.dart";

final GlobalKey discardPileKey = GlobalKey();
final GlobalKey listViewKey = GlobalKey();

class Animated {
  static Offset getPosition(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final scrollable = listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || scrollable == null) return Offset.zero;
    return box.localToGlobal(Offset.zero, ancestor: scrollable);
  }
  static const Offset moveBy = Offset(0, -100);

  final Widget widget;
  final Offset begin;
  final Offset end;
  final bool shouldFade;
  final Curve curve;
  final AnimationController animation;

  Animated.fade({
    required this.widget,
    required GlobalKey startAt,
    required this.animation,
    this.curve = Curves.easeOutQuart,
  }) :
    begin = getPosition(startAt),
    end = getPosition(startAt) + moveBy,
    shouldFade = true;

  Animated.move({
    required this.widget,
    required GlobalKey startAt,
    required GlobalKey endAt,
    required this.animation,
    Offset offset = Offset.zero,
    this.curve = Curves.easeOutQuart,
  }) :
    begin = getPosition(startAt),
    end = getPosition(endAt) + offset,
    shouldFade = false;

  Tween<Offset> get tween => Tween(begin: begin, end: end);
  Offset evaluate() => tween
    .evaluate(CurvedAnimation(parent: animation, curve: curve));

  double get opacity => shouldFade
    ? Tween<double>(begin: 1, end: 0).evaluate(animation)
    : 1;
}

class AnimationLayer extends StatefulWidget {
  @override
  AnimationLayerState createState() => AnimationLayerState();
}

class AnimationLayerState extends State<AnimationLayer> with TickerProviderStateMixin {
  StreamSubscription<void>? sub;

  final List<Animated> animations = [];

  @override
  void initState() {
    super.initState();
    sub = models.game.events.listen(animateEvent);
  }

  void onDone(AnimationController controller, AnimationStatus status) {
    switch(status) {
      case AnimationStatus.completed:
        animations.removeWhere((a) => a.animation == controller);
        controller.dispose();
      case _:
    }
  }

  @override
  void dispose() {
    unawaited(sub?.cancel());
    super.dispose();
  }

  GlobalKey playerKey(String name) => models.game.playerKeys[name]!;
  GlobalKey bankKey(String name) => models.game.bankKeys[name]!;
  GlobalKey cardKey(MCard card) => models.game.getCardKey(card);
  GlobalKey fromHand(String player, MCard card) => player == models.game.player.name
    ? cardKey(card) : playerKey(player);

  Future<void> animateEvent(GameEvent event) async {
    switch (event) {
      case BankEvent(:final player, :final value, :final card):
        animate((controller) => Animated.move(
          animation: controller,
          widget: CardWidget(card),
          startAt: fromHand(player, card),
          endAt: bankKey(player),
        ));
        animate((controller) => Animated.fade(
          startAt: bankKey(player),
          widget: Text("\$$value", style: context.textTheme.displaySmall?.copyWith(color: Colors.white)),
          animation: controller,
        ));
      case StealEvent(:final details):
        animate((controller) => Animated.fade(
          startAt: playerKey(details.waitingFor),
          widget: CardWidget(details.toGive == null ? slyDeal() : forcedDeal()),
          animation: controller,
        ));
      case StealStackEvent(:final details):
        animate((controller) => Animated.fade(
          startAt: playerKey(details.waitingFor),
          widget: CardWidget(dealBreaker()),
          animation: controller,
        ));
      case PaymentEvent(:final to, :final amount):
        animate((controller) => Animated.fade(
          startAt: bankKey(to),
          widget: Text("\$$amount", style: context.textTheme.displaySmall?.copyWith(color: Colors.white)),
          animation: controller,
        ));
      case JustSayNoEvent(:final player):
        animate((controller) => Animated.fade(
          startAt: playerKey(player),
          widget: CardWidget(JustSayNo()),
          animation: controller,
        ));
      case DiscardEvent(:final player, :final cards):
        for (final card in cards) {
          animate((controller) => Animated.move(
            widget: CardWidget(card),
            startAt: playerKey(player),
            endAt: discardPileKey,
            animation: controller,
          ));
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      case PropertyEvent(:final card, :final player, :final stackIndex):
        animate((controller) => Animated.move(
          animation: controller,
          startAt: fromHand(player, card),
          endAt: models.game.stackKeys[player]!,
          offset: const Offset(16, 0) + (const Offset(CardWidget.width + 32, 0) * stackIndex.toDouble()),
          widget: CardWidget(card),
        ));
      case _:
    }
  }

  void animate(Animated Function(AnimationController) func) {
    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    setState(() => animations.add(func(controller)));
    controller.addListener(() => setState(() { }));
    controller.addStatusListener((status) => onDone(controller, status));
    unawaited(controller.forward());
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final animation in animations)
        Positioned(
          left: animation.evaluate().dx,
          top: animation.evaluate().dy,
          child: Opacity(
            opacity: animation.opacity,
            child: SizedBox.fromSize(
              size: CardWidget.size,
              child: Center(child: animation.widget),
            ),
          ),
        ),
    ],
  );
}
