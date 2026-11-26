import "package:flutter_bloc/flutter_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "dart:io";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

const goldenKey=ValueKey("kitchen-golden");
const goldenSmallPhone=Size(640,360);
bool get goldensSupported=>Platform.isMacOS;
Future<void> loadAppFonts() async {
  final regular=FontLoader("Poppins")..addFont(rootBundle.load("assets/fonts/poppins/Poppins-Regular.ttf"))..addFont(rootBundle.load("assets/fonts/poppins/Poppins-Bold.ttf"));
  final my=FontLoader("NotoSansMyanmar")..addFont(rootBundle.load("assets/fonts/noto_sans_myanmar/NotoSansMyanmar.ttf"));
  final icons=FontLoader("MaterialIcons")..addFont(rootBundle.load("fonts/MaterialIcons-Regular.otf"));
  await Future.wait([regular.load(),my.load(),icons.load()]);
}
void useGoldenDevice(WidgetTester tester,{Size size=const Size(852,393),Brightness brightness=Brightness.light,Locale locale=const Locale("en")}){
  tester.view.devicePixelRatio=1;tester.view.physicalSize=size;
  tester.platformDispatcher.localeTestValue=locale;
  tester.platformDispatcher.platformBrightnessTestValue=brightness;
  tester.platformDispatcher.accessibilityFeaturesTestValue=const FakeAccessibilityFeatures(disableAnimations:true);
  addTearDown((){tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();tester.platformDispatcher.clearAllTestValues();});
}
Future<void> expectGolden(WidgetTester tester,String name)=>expectLater(find.byKey(goldenKey),matchesGoldenFile("goldens/$name.png"));
Future<void> waitForWidget(WidgetTester tester,Finder finder) async {
  for(var i=0;i<120;i++){
    await tester.pump(const Duration(milliseconds:17));
    if(finder.evaluate().isNotEmpty){return;}
    await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:20)));
  }
  debugDumpApp();
  expect(finder,findsWidgets);
}

class SilentTestAudio extends KitchenAudio {
  @override
  Future<void> preload() async {}
}
Widget withTestAudio(Widget child)=>RepositoryProvider<KitchenAudio>(create:(_)=>SilentTestAudio(),child:child);
