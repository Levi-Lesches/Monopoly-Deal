import "dart:async";

import "package:audioplayers/audioplayers.dart";
import "package:flutter/animation.dart";

import "service.dart";

class AudioService extends Service {
  bool silent = true;

  @override
  Future<void> init() async {
    AudioCache.instance.prefix = "audio/";
    const samples = ["card.mp3",  "money.mp3", "no.mp3", "set.mp3", "steal.mp3"];
    await AudioCache.instance.loadAll(samples);
  }

  Future<void> playAsset(String asset, {
    Duration? stopAt,
    Curve? volumeCurve = Curves.easeInOut,
    double speed = 1,
  }) async {
    if (silent) return;
    final player = AudioPlayer();

    // Fade the audio according to this curve:
    final volumeTween = volumeCurve == null ? null :
      CurveTween(curve: volumeCurve)
        .chain(Tween<double>(begin: 1, end: 0));

    // Play the audio
    await player.setVolume(1);
    await player.setSourceAsset(asset);
    await player.resume();
    await player.setPlaybackRate(speed);
    final totalDuration = (stopAt ?? (await player.getDuration())!) / speed;

    // As the audio plays, set its volume according to [volumeTween].
    player.onPositionChanged.listen((duration) {
      if (stopAt != null && duration >= stopAt) {
        unawaited(player.stop());
        return;
      } else if (volumeTween != null) {
        final relativePos = duration.inMilliseconds / totalDuration.inMilliseconds;
        if (relativePos < 0 || relativePos > 1) return;
        final volume = volumeTween.transform(relativePos);
        unawaited(player.setVolume(volume));
      }
    });

    // Play the audio and clean up after
    player.onPlayerComplete.listen((_) => player.dispose());
  }
}

extension on Duration {
  Duration operator /(double other) => Duration(milliseconds: inMilliseconds ~/ other);
}
