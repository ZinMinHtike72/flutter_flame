import "dart:async";
import "package:audioplayers/audioplayers.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/press_feedback.dart";

class KitchenAudio {
  final _pools = <String, AudioPool>{};
  AudioPlayer? _loop;
  bool _loopPlaying = false;
  bool _disposed = false;
  Future<void> preload() async {
    final cache = AudioCache(prefix: "packages/yumyum_kitchen/assets/audio/");
    await _preloadLoop(cache);
    for (final name in [
      "pack",
      "ceramic",
      "garnish",
      "serve",
      "streak",
      "burn",
      "boil",
    ]) {
      try {
        if (_disposed) {
          return;
        }
        final pool = await AudioPool.createFromAsset(
          path: "$name.wav",
          maxPlayers: 2,
          audioCache: cache,
        );
        if (_disposed) {
          await pool.dispose();
          return;
        }
        _pools[name] = pool;
      } on MissingPluginException {
        return;
      } on Exception catch (error) {
        debugPrint("Kitchen audio: $error");
        return;
      }
    }
  }

  Future<void> _preloadLoop(AudioCache cache) async {
    try {
      final player = AudioPlayer()..audioCache = cache;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(.32);
      await player.setSource(AssetSource("boil.wav"));
      if (_disposed) {
        await player.dispose();
        return;
      }
      _loop = player;
    } on MissingPluginException {
      return;
    } on Exception catch (error) {
      debugPrint("Kitchen audio loop: $error");
    }
  }

  /// Starts or stops the boil loop. Called on the rules step where the boil
  /// starts or ends, so sound and animation change together.
  void boilLoop({required bool on, required bool sound}) {
    final play = on && sound;
    if (play == _loopPlaying) {
      return;
    }
    _loopPlaying = play;
    final player = _loop;
    if (player == null) {
      return;
    }
    unawaited(_guard(play ? player.resume : player.pause));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Exception catch (error) {
      debugPrint("Kitchen audio loop: $error");
    }
  }

  void play(KitchenCue cue, {required bool sound, required bool haptics}) {
    final name = switch (cue) {
      KitchenCue.pack => "pack",
      KitchenCue.transfer || KitchenCue.discarded => "ceramic",
      KitchenCue.garnish => "garnish",
      KitchenCue.served => "serve",
      KitchenCue.streak => "streak",
      KitchenCue.burnt || KitchenCue.missed => "burn",
      KitchenCue.none => null,
    };
    if (sound && name != null) {
      unawaited(_sound(name));
    }
    if (haptics) {
      vibrate(hapticFor(cue));
    }
  }

  /// Fires [haptic] on the device (no-op for [Haptic.none]).
  void vibrate(Haptic haptic) {
    final call = switch (haptic) {
      Haptic.selection => HapticFeedback.selectionClick,
      Haptic.light => HapticFeedback.lightImpact,
      Haptic.medium => HapticFeedback.mediumImpact,
      Haptic.heavy => HapticFeedback.heavyImpact,
      Haptic.none => null,
    };
    if (call != null) {
      unawaited(call());
    }
  }

  Future<void> _sound(String name) async {
    try {
      await _pools[name]?.start(volume: .65);
    } on Exception catch (error) {
      debugPrint("Kitchen audio: $error");
    }
  }

  void ready({required bool sound}) {
    if (sound) {
      unawaited(_sound("boil"));
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _loop?.dispose();
    _loop = null;
    for (final pool in _pools.values) {
      await pool.dispose();
    }
  }
}
