import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/app/router.dart';
import 'package:voicemock/core/http/http.dart';
import 'package:voicemock/core/storage/disclosure_prefs.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/l10n/l10n.dart';

/// The main application widget.
class App extends StatelessWidget {
  const App({
    required this.prefs,
    required this.apiClient,
    this.routerConfig,
    super.key,
  });

  final SharedPreferences prefs;
  final ApiClient apiClient;
  final RouterConfig<Object>? routerConfig;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: prefs),
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider(create: (_) => DisclosurePrefs(prefs)),
        RepositoryProvider<SessionRepository>(
          create: (_) => SessionRepositoryImpl(
            remoteDataSource: SessionRemoteDataSource(apiClient: apiClient),
            localDataSource: SessionLocalDataSource(prefs: prefs),
          ),
        ),
      ],
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
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              ),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: VoiceMockColors.primaryContainer,
            space: VoiceMockSpacing.lg,
            thickness: 1,
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: VoiceMockColors.primary,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routerConfig ?? appRouter,
      ),
    );
  }
}
