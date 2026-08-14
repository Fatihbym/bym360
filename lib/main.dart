import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/save_settings.dart';
import 'l10n/app_localizations.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SaveSettings.initSharedPreferences();
  runApp(const Bym360App());
}

class Bym360App extends StatelessWidget {
  const Bym360App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SaveSettings.themeNotifier,
      builder: (context, isDark, child) {
        return ValueListenableBuilder<String>(
          valueListenable: SaveSettings.languageNotifier,
          builder: (context, langCode, child) {
            return MaterialApp(
              title: 'BYM 360',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              locale: Locale(langCode),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('tr', 'TR'),
                Locale('en', 'US'),
                Locale('de', 'DE'),
                Locale('az', 'AZ'),
              ],
              home: const SplashView(),
            );
          },
        );
      },
    );
  }
}
