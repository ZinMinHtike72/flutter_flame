import "dart:math";

import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/boil_sync.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/press_feedback.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("PressFeedback", () {
    test("snaps down at once and eases back within 120 ms", () {
      final press = PressFeedback();
      expect(press.scale(Station.pack, 0, 0), 1, reason: "nothing pressed");
      press.press(Station.pack, 0, 1000);
      expect(press.scale(Station.pack, 0, 1000), PressFeedback.pressedScale);
      // One 30 fps frame later (the next rendered frame) it is still pressed.
      final nextFrame = press.scale(Station.pack, 0, 1034);
      expect(nextFrame, inExclusiveRange(PressFeedback.pressedScale, 1));
      expect(press.scale(Station.pack, 0, 1060), greaterThan(nextFrame));
      expect(press.scale(Station.pack, 0, 1120), 1);
      expect(press.progress(Station.pack, 0, 990), 0);
    });

    test("only the pressed target responds", () {
      final press = PressFeedback()..press(Station.bowl, 1, 0);
      expect(press.scale(Station.bowl, 1, 10), lessThan(1));
      expect(press.scale(Station.bowl, 0, 10), 1);
      expect(press.scale(Station.pot, 1, 10), 1);
      press.press(Station.garnish, 2, 50);
      expect(
        press.scale(Station.bowl, 1, 60),
        1,
        reason: "one press at a time",
      );
      expect(press.scale(Station.garnish, 2, 60), lessThan(1));
    });
  });

  group("haptics", () {
    test(
      "every accepted step clicks; serve, streak and burn grow stronger",
      () {
        expect(hapticFor(KitchenCue.pack), Haptic.selection);
        expect(hapticFor(KitchenCue.transfer), Haptic.selection);
        expect(hapticFor(KitchenCue.garnish), Haptic.selection);
        expect(hapticFor(KitchenCue.discarded), Haptic.selection);
        expect(hapticFor(KitchenCue.served), Haptic.light);
        expect(hapticFor(KitchenCue.streak), Haptic.medium);
        expect(hapticFor(KitchenCue.burnt), Haptic.heavy);
        expect(hapticFor(KitchenCue.missed), Haptic.none);
        expect(hapticFor(KitchenCue.none), Haptic.none);
      },
    );

    test("reach the device only when haptics are on", () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == "HapticFeedback.vibrate") {
              calls.add("${call.arguments}");
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final audio = KitchenAudio()
        ..play(KitchenCue.pack, sound: false, haptics: true)
        ..play(KitchenCue.served, sound: false, haptics: true)
        ..play(KitchenCue.streak, sound: false, haptics: true)
        ..play(KitchenCue.burnt, sound: false, haptics: true)
        ..play(KitchenCue.missed, sound: false, haptics: true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, [
        "HapticFeedbackType.selectionClick",
        "HapticFeedbackType.lightImpact",
        "HapticFeedbackType.mediumImpact",
        "HapticFeedbackType.heavyImpact",
      ]);
      calls.clear();
      audio
        ..play(KitchenCue.pack, sound: false, haptics: false)
        ..play(KitchenCue.burnt, sound: false, haptics: false);
      await Future<void>.delayed(Duration.zero);
      expect(calls, isEmpty, reason: "haptics setting off");
    });
  });

  group("burnt pot shake", () {
    test("wobbles on the step it burns, decays, then stays still", () {
      final sync = BoilSync();
      final run = KitchenRun(
        shift: campaign[1],
        id: "shake",
        random: Random(1),
        upgrades: const {Upgrade.extraPot},
      );
      run.pots[0].phase = PotPhase.burnt;
      sync.step(run, (_) {});
      final at = run.now;
      final samples = [
        for (var t = 0; t < BoilSync.shakeMs; t += 10)
          sync.shake(0, at + t).abs(),
      ];
      final peak = samples.reduce(max);
      expect(peak, greaterThan(.01));
      expect(peak, lessThanOrEqualTo(BoilSync.shakeAmplitude));
      expect(sync.shake(0, at + BoilSync.shakeMs), 0);
      expect(sync.shake(1, at + 50), 0, reason: "the other pot is not burnt");
    });
  });
}
