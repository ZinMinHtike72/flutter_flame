import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "helpers/golden.dart";

void main(){
  testWidgets("standalone opens the branded kitchen",(tester)async{
    await getIt.reset();configureDependencies(flavor:AppFlavor.development);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(withTestAudio(const App()));
    await waitForWidget(tester,find.byType(MarketEntrance));
    expect(find.text("Play"),findsOneWidget);
    await tester.pumpWidget(const SizedBox());await tester.pump();
  });
}
