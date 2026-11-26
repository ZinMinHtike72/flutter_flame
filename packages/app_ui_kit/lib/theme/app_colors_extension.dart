import "package:flutter/material.dart";

/// Semantic accents plus the commission design's surface, text and status
/// colours (from `docs/prototypes/commission_ui.html`).
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.deviceLocation,
    required this.statusCompleted,
    required this.statusPending,
    required this.statusInProgress,
    required this.canvas,
    required this.card,
    required this.line,
    required this.textStrong,
    required this.textMuted,
    required this.textFaint,
    required this.primarySoft,
    required this.track,
    required this.compare,
    required this.good,
    required this.goodSoft,
    required this.bad,
    required this.badSoft,
    required this.warn,
    required this.warnSoft,
    required this.avatarEnd,
    required this.cardShadow,
    required this.heroStart,
    required this.heroMid,
    required this.heroEnd,
  });

  static const light = AppColorsExtension(
    deviceLocation: Color(0xff326BEA),
    statusCompleted: Color(0xff166534),
    statusPending: Color(0xff92400E),
    statusInProgress: Color(0xff1D4ED8),
    canvas: Color(0xffF5F7FC),
    card: Color(0xffFFFFFF),
    line: Color(0xffE6E8EF),
    textStrong: Color(0xff111827),
    textMuted: Color(0xff6B7280),
    textFaint: Color(0xff9CA3AF),
    primarySoft: Color(0xffEAEFFF),
    track: Color(0xffEDF0F7),
    compare: Color(0xffB8C3E6),
    good: Color(0xff15803D),
    goodSoft: Color(0xffDCFCE7),
    bad: Color(0xffB91C1C),
    badSoft: Color(0xffFEE2E2),
    warn: Color(0xff92400E),
    warnSoft: Color(0xffFEF3C7),
    avatarEnd: Color(0xff8A5CF6),
    cardShadow: Color(0x122F54E9),
    heroStart: Color(0xff2F54E9),
    heroMid: Color(0xff4D6BFF),
    heroEnd: Color(0xff7B5CFF),
  );

  static const dark = AppColorsExtension(
    deviceLocation: Color(0xff86AEFF),
    statusCompleted: Color(0xff86EFAC),
    statusPending: Color(0xffFCD34D),
    statusInProgress: Color(0xff93C5FD),
    canvas: Color(0xff151519),
    card: Color(0xff1F2027),
    line: Color(0xff2C2E37),
    textStrong: Color(0xffF3F4F6),
    textMuted: Color(0xffA1A7B3),
    textFaint: Color(0xff7A808C),
    primarySoft: Color(0xff262C4A),
    track: Color(0xff2A2C35),
    compare: Color(0xff4A5170),
    good: Color(0xff86EFAC),
    goodSoft: Color(0xff14321F),
    bad: Color(0xffFCA5A5),
    badSoft: Color(0xff3A1717),
    warn: Color(0xffFCD34D),
    warnSoft: Color(0xff3A2E10),
    avatarEnd: Color(0xff8A5CF6),
    cardShadow: Color(0x00000000),
    heroStart: Color(0xff2F54E9),
    heroMid: Color(0xff4D6BFF),
    heroEnd: Color(0xff7B5CFF),
  );

  final Color deviceLocation;
  final Color statusCompleted;
  final Color statusPending;
  final Color statusInProgress;

  /// Page background behind cards.
  final Color canvas;

  /// Card surface.
  final Color card;

  /// Hairline borders and dividers.
  final Color line;

  /// Main text.
  final Color textStrong;

  /// Secondary text.
  final Color textMuted;

  /// Tertiary text and idle icons.
  final Color textFaint;

  /// Tinted primary background for pills and selections.
  final Color primarySoft;

  /// Empty part of bars and meters.
  final Color track;

  /// Unselected bars and last month's values in charts.
  final Color compare;

  /// Positive text.
  final Color good;

  /// Positive background.
  final Color goodSoft;

  /// Negative text.
  final Color bad;

  /// Negative background.
  final Color badSoft;

  /// Warning text.
  final Color warn;

  /// Warning background.
  final Color warnSoft;

  /// Second stop of the avatar gradient.
  final Color avatarEnd;

  /// Soft brand shadow under cards; transparent in dark mode.
  final Color cardShadow;

  /// Hero gradient start.
  final Color heroStart;

  /// Hero gradient middle.
  final Color heroMid;

  /// Hero gradient end.
  final Color heroEnd;

  @override
  AppColorsExtension copyWith({
    Color? deviceLocation,
    Color? statusCompleted,
    Color? statusPending,
    Color? statusInProgress,
    Color? canvas,
    Color? card,
    Color? line,
    Color? textStrong,
    Color? textMuted,
    Color? textFaint,
    Color? primarySoft,
    Color? track,
    Color? compare,
    Color? good,
    Color? goodSoft,
    Color? bad,
    Color? badSoft,
    Color? warn,
    Color? warnSoft,
    Color? avatarEnd,
    Color? cardShadow,
    Color? heroStart,
    Color? heroMid,
    Color? heroEnd,
  }) => AppColorsExtension(
    deviceLocation: deviceLocation ?? this.deviceLocation,
    statusCompleted: statusCompleted ?? this.statusCompleted,
    statusPending: statusPending ?? this.statusPending,
    statusInProgress: statusInProgress ?? this.statusInProgress,
    canvas: canvas ?? this.canvas,
    card: card ?? this.card,
    line: line ?? this.line,
    textStrong: textStrong ?? this.textStrong,
    textMuted: textMuted ?? this.textMuted,
    textFaint: textFaint ?? this.textFaint,
    primarySoft: primarySoft ?? this.primarySoft,
    track: track ?? this.track,
    compare: compare ?? this.compare,
    good: good ?? this.good,
    goodSoft: goodSoft ?? this.goodSoft,
    bad: bad ?? this.bad,
    badSoft: badSoft ?? this.badSoft,
    warn: warn ?? this.warn,
    warnSoft: warnSoft ?? this.warnSoft,
    avatarEnd: avatarEnd ?? this.avatarEnd,
    cardShadow: cardShadow ?? this.cardShadow,
    heroStart: heroStart ?? this.heroStart,
    heroMid: heroMid ?? this.heroMid,
    heroEnd: heroEnd ?? this.heroEnd,
  );

  @override
  AppColorsExtension lerp(covariant AppColorsExtension? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorsExtension(
      deviceLocation: mix(deviceLocation, other.deviceLocation),
      statusCompleted: mix(statusCompleted, other.statusCompleted),
      statusPending: mix(statusPending, other.statusPending),
      statusInProgress: mix(statusInProgress, other.statusInProgress),
      canvas: mix(canvas, other.canvas),
      card: mix(card, other.card),
      line: mix(line, other.line),
      textStrong: mix(textStrong, other.textStrong),
      textMuted: mix(textMuted, other.textMuted),
      textFaint: mix(textFaint, other.textFaint),
      primarySoft: mix(primarySoft, other.primarySoft),
      track: mix(track, other.track),
      compare: mix(compare, other.compare),
      good: mix(good, other.good),
      goodSoft: mix(goodSoft, other.goodSoft),
      bad: mix(bad, other.bad),
      badSoft: mix(badSoft, other.badSoft),
      warn: mix(warn, other.warn),
      warnSoft: mix(warnSoft, other.warnSoft),
      avatarEnd: mix(avatarEnd, other.avatarEnd),
      cardShadow: mix(cardShadow, other.cardShadow),
      heroStart: mix(heroStart, other.heroStart),
      heroMid: mix(heroMid, other.heroMid),
      heroEnd: mix(heroEnd, other.heroEnd),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColorsExtension.dark
          : AppColorsExtension.light);
}
