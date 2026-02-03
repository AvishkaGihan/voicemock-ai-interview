import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/app/router.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/l10n/l10n.dart';

/// The main application widget.
class App extends StatelessWidget {
  const App({required this.prefs, super.key});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: prefs,
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: VoiceMockColors.primary,
            surface: VoiceMockColors.surface,
          ),
          scaffoldBackgroundColor: VoiceMockColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: VoiceMockColors.background,
            foregroundColor: VoiceMockColors.textPrimary,
            elevation: 0,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
      ),
    );
  }
}
