import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";

/// What the HUD, the receipt and saving read from a running day, whether it
/// is the old noodle stall (`KitchenRun`) or the restaurant
/// (`RestaurantRun`).
abstract interface class ShiftRun {
  /// Unique per run, so a result is banked exactly once.
  String get id;

  /// The level (day) number, 1–12.
  int get number;
  Goal get goal;
  int get target;

  /// The featured noodle pack (receipt product card).
  NoodleProduct get product;

  bool get paused;
  set paused(bool value);
  bool get ended;
  bool get won;
  int get coins;
  int get served;
  int get missed;
  int get bestChain;

  /// Progress towards [target]: guests served or coins earned.
  int get progress;
  int get secondsLeft;

  /// The current earnings multiplier in percent (100 = ×1.00).
  int get multiplierPercent;

  /// Tutorial step; [Guide.done] when there is none.
  Guide get guide;

  /// Changes whenever something the HUD shows may have changed.
  int get feedbackSequence;

  /// Runs the rules for [ms] milliseconds.
  void advance(int ms);
}
