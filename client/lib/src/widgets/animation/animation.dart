import "dart:async";

import "package:flutter/material.dart";
import "package:mdeal/data.dart";
import "package:mdeal/models.dart";
import "package:mdeal/widgets.dart";

final GlobalKey discardPileKey = GlobalKey();
final GlobalKey pickPileKey = GlobalKey();
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
  final Size size;
  final AnimationController animation;

  Animated.fade({
    required this.widget,
    required GlobalKey startAt,
    required this.animation,
    this.curve = Curves.easeOutQuart,
  }) :
    begin = getPosition(startAt),
    end = getPosition(startAt) + moveBy,
    size = CardWidget.size,
    shouldFade = true;

  Animated.move({
    required this.widget,
    required GlobalKey startAt,
    required GlobalKey endAt,
    required this.animation,
    Offset offset = Offset.zero,
    this.size = CardWidget.size,
    this.curve = Curves.easeOutQuart,
  }) :
    begin = getPosition(startAt),
    end = getPosition(endAt) + offset,
    shouldFade = false;

  Tween<Offset> get tween => Tween(begin: begin, end: end);
  Offset evaluate() => tween
    .evaluate(CurvedAnimation(parent: animation, curve: curve));

  double get opacity => shouldFade
    ? Tween<double>(begin: 1, end: 0).evaluate(CurvedAnimation(parent: animation, curve: curve))
    : 1;
}

class AnimationLayer extends StatefulWidget {
  @override
  AnimationLayerState createState() => AnimationLayerState();
}

class AnimationLayerState extends State<AnimationLayer> with TickerProviderStateMixin {
  static const cardDelay = Duration(milliseconds: 250);
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
    for (final animation in animations) {
      animation.animation.dispose();
    }
    animations.clear();
    super.dispose();
  }

  GlobalKey playerKey(String name) => models.game.playerKeys[name]!;
  GlobalKey bankKey(String name) => models.game.bankKeys[name]!;
  GlobalKey cardKey(MCard card) => models.game.getCardKey(card);
  GlobalKey fromHand(String player, MCard card) => player == models.game.player.name
    ? cardKey(card) : playerKey(player);

  Future<void> animateEvent(GameEvent event) async {
    switch (event) {
      case DealEvent(:final amount, :final player):
        models.audio.playCard(amount, speed: 1.2);
        for (final _ in range(amount)) {
          animate(duration: const Duration(milliseconds: 400 ~/ 1.2), (controller) => Animated.move(
            animation: controller,
            widget: const EmptyCardWidget(color: Colors.blueGrey, text: "Deal"),
            startAt: pickPileKey,
            endAt: playerKey(player),
            offset: const Offset(0, CardWidget.height * -1/2),
          ));
          await Future<void>.delayed(AudioModel.cardDelay);
        }
      case BankEvent(:final player, :final value, :final card):
        models.audio.playMoney();
        animate((controller) => Animated.move(
          animation: controller,
          widget: CardWidget(card),
          startAt: fromHand(player, card),
          endAt: bankKey(player),
        ));
        await Future<void>.delayed(cardDelay);
        animate(duration: const Duration(seconds: 2), (controller) => Animated.fade(
          startAt: bankKey(player),
          widget: Text("\$$value", style: context.textTheme.displaySmall?.copyWith(color: Colors.white)),
          animation: controller,
        ));
      case StealEvent(:final details):
        models.audio.playSteal();
        animate(duration: const Duration(milliseconds: 1000), (controller) => Animated.fade(
          startAt: playerKey(details.waitingFor),
          widget: CardWidget(details.toGiveUuid == null ? slyDeal() : forcedDeal()),
          animation: controller,
          curve: Curves.easeIn,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        models.audio.playCard(1);
        animate(duration: const Duration(milliseconds: 500), (controller) => Animated.move(
          animation: controller,
          startAt: playerKey(details.waitingFor),
          endAt: playerKey(details.causedBy),
          widget: CardWidget(details.toSteal),
        ));
        if (details.toGive case final MCard card) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          models.audio.playCard(1);
          animate(duration: const Duration(milliseconds: 500), (controller) => Animated.move(
            animation: controller,
            startAt: playerKey(details.causedBy),
            endAt: playerKey(details.waitingFor),
            widget: CardWidget(card),
          ));
        }
      case StealStackEvent(:final details):
        models.audio.playSteal();
        animate(duration: const Duration(seconds: 1), (controller) => Animated.fade(
          startAt: playerKey(details.waitingFor),
          widget: CardWidget(dealBreaker()),
          animation: controller,
          curve: Curves.easeIn,
        ));
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        final stack = models.game.game.allPlayers
          .firstWhere((p) => p.name == details.waitingFor)
          .getStackWithSet(details.color)!;
        animate((controller) => Animated.move(
          animation: controller,
          startAt: playerKey(details.waitingFor),
          endAt: playerKey(details.causedBy),
          widget: StackWidget(stack),
          size: StackWidget.getSizeFor(stack),
        ));
      case PaymentEvent(:final to, :final amount, :final cards, :final from):
        models.audio.playMoney();
        for (final card in cards) {
          animate((controller) => Animated.move(
            animation: controller,
            startAt: bankKey(from),
            endAt: bankKey(to),
            widget: CardWidget(card),
          ));
          await Future<void>.delayed(cardDelay);
        }
        animate(duration: const Duration(seconds: 2), (controller) => Animated.fade(
          startAt: bankKey(to),
          widget: Text("\$$amount", style: context.textTheme.displaySmall?.copyWith(color: Colors.white)),
          animation: controller,
        ));
      case JustSayNoEvent(:final player):
        models.audio.playNo();
        animate(duration: const Duration(seconds: 1), (controller) => Animated.fade(
          startAt: playerKey(player),
          widget: CardWidget(JustSayNo()),
          animation: controller,
        ));
      case DiscardEvent(:final player, :final cards):
        models.audio.playCard(cards.length);
        for (final card in cards) {
          animate((controller) => Animated.move(
            widget: CardWidget(card),
            startAt: playerKey(player),
            endAt: discardPileKey,
            animation: controller,
          ));
          await Future<void>.delayed(cardDelay);
        }
      case PropertyEvent(:final card, :final player, :final stackIndex):
        models.audio.playCard(1);
        animate(duration: const Duration(milliseconds: 800), (controller) => Animated.move(
          animation: controller,
          startAt: fromHand(player, card),
          endAt: models.game.stackKeys[player]!,
          offset: const Offset(16, 0) + (const Offset(CardWidget.width + 32, 0) * stackIndex.toDouble()),
          widget: CardWidget(card),
        ));
      case ActionCardEvent(:final card, :final player):
        models.audio.playCard(1);
        animate(duration: const Duration(milliseconds: 800), (controller) => Animated.move(
          startAt: fromHand(player, card),
          endAt: discardPileKey,
          widget: CardWidget(card),
          animation: controller,
        ));
      case PassGoEvent(:final player, :final card):
        models.audio.playCard(1);
        animate(duration: const Duration(milliseconds: 800), (controller) => Animated.move(
          startAt: fromHand(player, card),
          endAt: discardPileKey,
          widget: CardWidget(card),
          animation: controller,
        ));
      case SimpleEvent():
    }
  }

  void animate(Animated Function(AnimationController) func, {Duration duration = const Duration(milliseconds: 400)}) {
    if (!context.mounted) return;
    final controller = AnimationController(vsync: this, duration: duration);
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
              size: animation.size,
              child: Center(child: animation.widget),
            ),
          ),
        ),
    ],
  );
}
