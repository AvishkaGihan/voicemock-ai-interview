import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/core/connectivity/connectivity.dart';
import 'package:voicemock/core/http/http.dart';
import 'package:voicemock/core/permissions/permissions.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_cubit.dart';
import 'package:voicemock/features/interview/presentation/view/setup_view.dart';

/// Setup page providing the ConfigurationCubit, PermissionCubit, and
/// SessionCubit to the SetupView.
///
/// This is the route entrypoint for the interview setup screen.
class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  /// Route name for navigation.
  static const String routeName = '/setup';

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<SharedPreferences>();
    final apiClient = context.read<ApiClient>();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SessionRepository>(
          create: (_) => SessionRepositoryImpl(
            remoteDataSource: SessionRemoteDataSource(apiClient: apiClient),
            localDataSource: SessionLocalDataSource(prefs: prefs),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              final cubit = ConfigurationCubit(prefs: prefs);
              unawaited(cubit.loadSavedConfiguration());
              return cubit;
            },
          ),
          BlocProvider(
            create: (context) {
              final cubit = PermissionCubit(
                permissionService: const MicrophonePermissionService(),
              );
              unawaited(cubit.checkPermission());
              return cubit;
            },
          ),
          BlocProvider(
            create: (context) => SessionCubit(
              repository: context.read<SessionRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) {
              final cubit = ConnectivityCubit(connectivity: Connectivity())
                ..startListening();
              unawaited(cubit.checkConnectivity());
              return cubit;
            },
          ),
        ],
        child: const SetupView(),
      ),
    );
  }
}
