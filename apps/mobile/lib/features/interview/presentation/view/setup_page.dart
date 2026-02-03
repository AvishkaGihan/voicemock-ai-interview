import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/core/permissions/permissions.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/view/setup_view.dart';

/// Setup page providing the ConfigurationCubit and PermissionCubit to the
/// SetupView.
///
/// This is the route entrypoint for the interview setup screen.
class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  /// Route name for navigation.
  static const String routeName = '/setup';

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final prefs = context.read<SharedPreferences>();
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
      ],
      child: const SetupView(),
    );
  }
}
