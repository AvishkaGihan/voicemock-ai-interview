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
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: VoiceMockColors.primary,
            brightness: Brightness.dark,
            surface: VoiceMockColors.surface,
          ),
          scaffoldBackgroundColor: VoiceMockColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: VoiceMockColors.background,
            foregroundColor: VoiceMockColors.textPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: VoiceMockColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
              side: const BorderSide(color: VoiceMockColors.surfaceBorder),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: VoiceMockColors.primary,
              foregroundColor: VoiceMockColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoiceMockRadius.full),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: VoiceMockColors.textPrimary,
              side: const BorderSide(color: VoiceMockColors.surfaceBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoiceMockRadius.full),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: VoiceMockColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoiceMockRadius.md),
              ),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: VoiceMockColors.surfaceBorder,
            space: VoiceMockSpacing.lg,
            thickness: 1,
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: VoiceMockColors.primary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: VoiceMockColors.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
              side: const BorderSide(color: VoiceMockColors.surfaceBorder),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: VoiceMockColors.surface,
            surfaceTintColor: Colors.transparent,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: VoiceMockColors.surfaceElevated,
            contentTextStyle: VoiceMockTypography.small.copyWith(
              color: VoiceMockColors.textPrimary,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VoiceMockRadius.md),
            ),
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
