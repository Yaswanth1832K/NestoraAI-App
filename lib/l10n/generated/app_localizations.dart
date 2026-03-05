import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_or.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('ml'),
    Locale('or'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @loginAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Login & Security'**
  String get loginAndSecurity;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @hostingAndRenting.
  ///
  /// In en, this message translates to:
  /// **'Hosting & Renting'**
  String get hostingAndRenting;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @visitRequests.
  ///
  /// In en, this message translates to:
  /// **'Visit Requests'**
  String get visitRequests;

  /// No description provided for @myVisits.
  ///
  /// In en, this message translates to:
  /// **'My Visits'**
  String get myVisits;

  /// No description provided for @rentalPreferences.
  ///
  /// In en, this message translates to:
  /// **'Rental Preferences'**
  String get rentalPreferences;

  /// No description provided for @savedProperties.
  ///
  /// In en, this message translates to:
  /// **'Saved Properties'**
  String get savedProperties;

  /// No description provided for @financialAndMessages.
  ///
  /// In en, this message translates to:
  /// **'Financial & Messages'**
  String get financialAndMessages;

  /// No description provided for @paymentsAndPayouts.
  ///
  /// In en, this message translates to:
  /// **'Payments & Payouts'**
  String get paymentsAndPayouts;

  /// No description provided for @messageSettings.
  ///
  /// In en, this message translates to:
  /// **'Message Settings'**
  String get messageSettings;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @safetyCenter.
  ///
  /// In en, this message translates to:
  /// **'Safety Center'**
  String get safetyCenter;

  /// No description provided for @reportConcern.
  ///
  /// In en, this message translates to:
  /// **'Report a Concern'**
  String get reportConcern;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Language and Region'**
  String get languageAndRegion;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @where.
  ///
  /// In en, this message translates to:
  /// **'Where?'**
  String get where;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get when;

  /// No description provided for @who.
  ///
  /// In en, this message translates to:
  /// **'Who'**
  String get who;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchDestinations.
  ///
  /// In en, this message translates to:
  /// **'Search destinations'**
  String get searchDestinations;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @suggestedDestinations.
  ///
  /// In en, this message translates to:
  /// **'Suggested destinations'**
  String get suggestedDestinations;

  /// No description provided for @guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guests;

  /// No description provided for @bookingAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available this weekend'**
  String get bookingAvailable;

  /// No description provided for @homes.
  ///
  /// In en, this message translates to:
  /// **'Homes'**
  String get homes;

  /// No description provided for @experiences.
  ///
  /// In en, this message translates to:
  /// **'Experiences'**
  String get experiences;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @anywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get anywhere;

  /// No description provided for @anyWeek.
  ///
  /// In en, this message translates to:
  /// **'Any week'**
  String get anyWeek;

  /// No description provided for @addDates.
  ///
  /// In en, this message translates to:
  /// **'Add dates'**
  String get addDates;

  /// No description provided for @addGuests.
  ///
  /// In en, this message translates to:
  /// **'Add guests'**
  String get addGuests;

  /// No description provided for @noRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'No recent searches'**
  String get noRecentSearches;

  /// No description provided for @sampleDateRange.
  ///
  /// In en, this message translates to:
  /// **'6-8 Mar'**
  String get sampleDateRange;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @hyderabad.
  ///
  /// In en, this message translates to:
  /// **'Hyderabad'**
  String get hyderabad;

  /// No description provided for @goa.
  ///
  /// In en, this message translates to:
  /// **'Goa'**
  String get goa;

  /// No description provided for @findWhatsAroundYou.
  ///
  /// In en, this message translates to:
  /// **'Find what\'s around you'**
  String get findWhatsAroundYou;

  /// No description provided for @greatForWeekendGetaway.
  ///
  /// In en, this message translates to:
  /// **'Great for a weekend getaway'**
  String get greatForWeekendGetaway;

  /// No description provided for @sunAndSand.
  ///
  /// In en, this message translates to:
  /// **'Sun and sand'**
  String get sunAndSand;

  /// No description provided for @chooseYourTravelDates.
  ///
  /// In en, this message translates to:
  /// **'Choose your travel dates'**
  String get chooseYourTravelDates;

  /// No description provided for @pickDates.
  ///
  /// In en, this message translates to:
  /// **'Pick Dates'**
  String get pickDates;

  /// No description provided for @numberOfPeople.
  ///
  /// In en, this message translates to:
  /// **'Number of people'**
  String get numberOfPeople;

  /// No description provided for @rentalsIn.
  ///
  /// In en, this message translates to:
  /// **'{count} rentals in {city}'**
  String rentalsIn(Object city, Object count);

  /// No description provided for @allHomes.
  ///
  /// In en, this message translates to:
  /// **'All Homes'**
  String get allHomes;

  /// No description provided for @homeServices.
  ///
  /// In en, this message translates to:
  /// **'Home Services'**
  String get homeServices;

  /// No description provided for @expertHelp.
  ///
  /// In en, this message translates to:
  /// **'Expert help at your doorstep'**
  String get expertHelp;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @availableInCity.
  ///
  /// In en, this message translates to:
  /// **'Available in {city} this weekend'**
  String availableInCity(Object city);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'hi',
    'ml',
    'or',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ml':
      return AppLocalizationsMl();
    case 'or':
      return AppLocalizationsOr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
