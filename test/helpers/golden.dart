import "dart:io";
import "dart:math";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";

const goldenKey = ValueKey("kitchen-golden");

/// Small landscape phone.
const goldenSmallPhone = Size(640, 360);

/// Notched landscape phone (iPhone 14 Pro class).
const goldenPhone = Size(852, 393);

/// Landscape view padding of a notched phone: cutout left, home bar bottom.
const notchedPadding = FakeViewPadding(left: 59, right: 59, bottom: 21);

bool get goldensSupported => Platform.isMacOS;

Future<void> loadAppFonts() async {
  final regular = FontLoader("Poppins")
    ..addFont(rootBundle.load("assets/fonts/poppins/Poppins-Regular.ttf"))
    ..addFont(rootBundle.load("assets/fonts/poppins/Poppins-Bold.ttf"));
  final myanmar = FontLoader("NotoSansMyanmar")
    ..addFont(
      rootBundle.load("assets/fonts/noto_sans_myanmar/NotoSansMyanmar.ttf"),
    );
  final icons = FontLoader("MaterialIcons")
    ..addFont(rootBundle.load("fonts/MaterialIcons-Regular.otf"));
  await Future.wait([regular.load(), myanmar.load(), icons.load()]);
}

void useGoldenDevice(
  WidgetTester tester, {
  Size size = goldenPhone,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale("en"),
  FakeViewPadding padding = FakeViewPadding.zero,
}) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size
    ..padding = padding
    ..viewPadding = padding;
  tester.platformDispatcher
    ..localeTestValue = locale
    ..localesTestValue = [locale]
    ..platformBrightnessTestValue = brightness
    ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio()
      ..resetPadding()
      ..resetViewPadding();
    tester.platformDispatcher.clearAllTestValues();
  });
}

Future<void> expectGolden(WidgetTester tester, String name) =>
    expectLater(find.byKey(goldenKey), matchesGoldenFile("goldens/$name.png"));

Future<void> waitForWidget(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 17));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(finder, findsWidgets);
}

/// Pumps two 30 fps frames so the throttled game steps and repaints.
Future<void> settleFrames(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.pump(const Duration(milliseconds: 34));
  }
}

class SilentTestAudio extends KitchenAudio {
  @override
  Future<void> preload() async {}
}

/// Silent audio and a seeded [Random] so every shift renders the same way.
Widget withTestAudio(Widget child) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<KitchenAudio>(create: (_) => SilentTestAudio()),
    RepositoryProvider<Random>(create: (_) => Random(7)),
  ],
  child: child,
);
