import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/theme/app_theme.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/core/theme/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:house_rental/l10n/app_localizations.dart';
import 'package:house_rental/core/providers/locale_provider.dart';

/// Root application widget.
class HouseRentalApp extends ConsumerWidget {
  const HouseRentalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Nestora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
