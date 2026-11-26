import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'kitchen_strings_en.dart';
import 'kitchen_strings_my.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of KitchenStrings
/// returned by `KitchenStrings.of(context)`.
///
/// Applications need to include `KitchenStrings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/kitchen_strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: KitchenStrings.localizationsDelegates,
///   supportedLocales: KitchenStrings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the KitchenStrings.supportedLocales
/// property.
abstract class KitchenStrings {
  KitchenStrings(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static KitchenStrings of(BuildContext context) {
    return Localizations.of<KitchenStrings>(context, KitchenStrings)!;
  }

  static const LocalizationsDelegate<KitchenStrings> delegate =
      _KitchenStringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my'),
  ];

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Yangon Night Market'**
  String get market;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Madness'**
  String get title;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Shift tickets'**
  String get tickets;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening the stall'**
  String get opening;

  /// No description provided for @rush.
  ///
  /// In en, this message translates to:
  /// **'Dinner rush'**
  String get rush;

  /// No description provided for @closing.
  ///
  /// In en, this message translates to:
  /// **'Last orders'**
  String get closing;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start shift'**
  String get start;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'Personal best'**
  String get best;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @clock.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get clock;

  /// No description provided for @combo.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get combo;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Kitchen paused'**
  String get paused;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart shift'**
  String get restart;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Leave kitchen'**
  String get exit;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get music;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get vibration;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @won.
  ///
  /// In en, this message translates to:
  /// **'Shift complete!'**
  String get won;

  /// No description provided for @lost.
  ///
  /// In en, this message translates to:
  /// **'Time’s up!'**
  String get lost;

  /// No description provided for @served.
  ///
  /// In en, this message translates to:
  /// **'Served'**
  String get served;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next shift'**
  String get next;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Kitchen upgrades'**
  String get shop;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get balance;

  /// No description provided for @extraPot.
  ///
  /// In en, this message translates to:
  /// **'Second pot'**
  String get extraPot;

  /// No description provided for @fastBoil.
  ///
  /// In en, this message translates to:
  /// **'Faster stove'**
  String get fastBoil;

  /// No description provided for @premiumBowl.
  ///
  /// In en, this message translates to:
  /// **'Premium bowls'**
  String get premiumBowl;

  /// No description provided for @potHint.
  ///
  /// In en, this message translates to:
  /// **'Cook two portions at once'**
  String get potHint;

  /// No description provided for @boilHint.
  ///
  /// In en, this message translates to:
  /// **'Boil in 2.1 seconds'**
  String get boilHint;

  /// No description provided for @valueHint.
  ///
  /// In en, this message translates to:
  /// **'+25 coins per dish'**
  String get valueHint;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get owned;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Meet the noodles'**
  String get product;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original Chicken'**
  String get original;

  /// No description provided for @xcite.
  ///
  /// In en, this message translates to:
  /// **'Xcite Tom Yum Chicken'**
  String get xcite;

  /// No description provided for @ultra.
  ///
  /// In en, this message translates to:
  /// **'Ultra Mala Xiang Guo'**
  String get ultra;

  /// No description provided for @guidePack.
  ///
  /// In en, this message translates to:
  /// **'Tap the noodle pack'**
  String get guidePack;

  /// No description provided for @guideWait.
  ///
  /// In en, this message translates to:
  /// **'Watch the pot boil'**
  String get guideWait;

  /// No description provided for @guidePot.
  ///
  /// In en, this message translates to:
  /// **'Tap the ready pot'**
  String get guidePot;

  /// No description provided for @guideServe.
  ///
  /// In en, this message translates to:
  /// **'Tap your bowl to serve'**
  String get guideServe;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard bowl'**
  String get discard;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Opening the stall…'**
  String get loading;

  /// No description provided for @problem.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save or load kitchen progress.'**
  String get problem;

  /// No description provided for @linkFailed.
  ///
  /// In en, this message translates to:
  /// **'Product page is unavailable.'**
  String get linkFailed;

  /// No description provided for @counter.
  ///
  /// In en, this message translates to:
  /// **'Kitchen counter'**
  String get counter;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @boil.
  ///
  /// In en, this message translates to:
  /// **'Pot'**
  String get boil;

  /// No description provided for @bowl.
  ///
  /// In en, this message translates to:
  /// **'Bowl'**
  String get bowl;

  /// No description provided for @noodles.
  ///
  /// In en, this message translates to:
  /// **'Noodles'**
  String get noodles;

  /// No description provided for @onion.
  ///
  /// In en, this message translates to:
  /// **'Spring onion'**
  String get onion;

  /// No description provided for @egg.
  ///
  /// In en, this message translates to:
  /// **'Egg'**
  String get egg;

  /// No description provided for @lime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get lime;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'First order'**
  String get tutorial;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Back to tickets'**
  String get complete;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get bestStreak;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;
}

class _KitchenStringsDelegate extends LocalizationsDelegate<KitchenStrings> {
  const _KitchenStringsDelegate();

  @override
  Future<KitchenStrings> load(Locale locale) {
    return SynchronousFuture<KitchenStrings>(lookupKitchenStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_KitchenStringsDelegate old) => false;
}

KitchenStrings lookupKitchenStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return KitchenStringsEn();
    case 'my':
      return KitchenStringsMy();
  }

  throw FlutterError(
    'KitchenStrings.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
