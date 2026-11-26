import "dart:async";
import "package:audioplayers/audioplayers.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

class KitchenAudio {
  final _pools = <String, AudioPool>{};
  bool _disposed = false;
  Future<void> preload() async {
    final cache = AudioCache(prefix: "packages/yumyum_kitchen/assets/audio/");
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
    if (haptics && (cue == KitchenCue.served || cue == KitchenCue.streak)) {
      unawaited(HapticFeedback.lightImpact());
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
    for (final pool in _pools.values) {
      await pool.dispose();
    }
  }
}
