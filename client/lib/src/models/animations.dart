import "dart:async";

import "package:flutter/widgets.dart";
import "package:mdeal/data.dart";
import "package:mdeal/widgets.dart";

import "audio.dart";

mixin AnimationModel on ChangeNotifier {
  bool enableAnimations = false;
  void toggleAnimations() {
    enableAnimations = !enableAnimations;
    notifyListeners();
  }

  Set<EventID> finishedEvents = {};
  final _eventsController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventsController.stream;
  Future<void> addEvents(Iterable<GameEvent> events) async {
    for (final event in events) {
      if (finishedEvents.contains(event.id)) continue;
      finishedEvents.add(event.id);
      if (enableAnimations) {
        _eventsController.add(event);
        await Future<void>.delayed(event.animationDelay);
      }
    }
  }

  GameState get game;
  late final Map<String, GlobalKey> playerKeys = {
    for (final player in game.allPlayers)
      player.name: GlobalKey(),
  };

  late final Map<String, GlobalKey> bankKeys = {
    for (final player in game.allPlayers)
      player.name: GlobalKey(),
  };

  late final Map<String, GlobalKey> stackKeys = {
    for (final player in game.allPlayers)
      player.name: GlobalKey(),
  };

  final Map<CardUuid, GlobalKey> _cardKeys = {};
  GlobalKey getCardKey(MCard card) => _cardKeys.putIfAbsent(card.uuid, GlobalKey.new);
}

extension on GameEvent {
  Duration get animationDelay => switch (this) {
    BankEvent() => AnimationLayerState.cardDelay,
    PropertyEvent() => const Duration(milliseconds: 800),
    DealEvent(:final amount) => AudioModel.cardDelay * amount,
    DiscardEvent(:final cards) => AnimationLayerState.cardDelay * cards.length,
    StealEvent(:final details) => Duration(milliseconds: details.isTrade ? 2000 : 1500),
    PaymentEvent(:final amount) => AnimationLayerState.cardDelay * amount,
    ActionCardEvent() => const Duration(milliseconds: 800),
    SimpleEvent() => Duration.zero,
    StealStackEvent() => const Duration(milliseconds: 1400),
    JustSayNoEvent() => const Duration(seconds: 1),
    PassGoEvent() => const Duration(milliseconds: 800),
  };
}
