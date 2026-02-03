import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/permissions/permissions.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/view/permission_rationale_view.dart';

/// Page wrapper for the permission rationale screen.
///
/// Provides the PermissionCubit to the PermissionRationaleView.
class PermissionRationalePage extends StatelessWidget {
  const PermissionRationalePage({super.key});

  /// Route name for navigation.
  static const String routeName = '/permission';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PermissionCubit(
        permissionService: const MicrophonePermissionService(),
      ),
      child: const PermissionRationaleView(),
    );
  }
}
