import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';

/// Cubit for managing microphone permission state.
///
/// Handles checking and requesting microphone permission,
/// and opening app settings for permanently denied cases.
class PermissionCubit extends Cubit<PermissionState> {
  PermissionCubit({
    required PermissionService permissionService,
  }) : _permissionService = permissionService,
       super(PermissionState.initial());

  final PermissionService _permissionService;

  /// Checks the current microphone permission status.
  ///
  /// Updates state with the result without prompting the user.
  Future<void> checkPermission() async {
    emit(state.copyWith(isLoading: true));

    try {
      final status = await _permissionService.checkMicrophonePermission();
      emit(
        state.copyWith(
          status: status,
          isLoading: false,
          hasChecked: true,
        ),
      );
    } on Exception {
      // If check fails, keep current status but mark as checked
      emit(
        state.copyWith(
          isLoading: false,
          hasChecked: true,
        ),
      );
    }
  }

  /// Requests microphone permission from the user.
  ///
  /// Shows the system permission dialog and updates state with the result.
  Future<void> requestPermission() async {
    emit(state.copyWith(isLoading: true));

    try {
      final status = await _permissionService.requestMicrophonePermission();
      emit(
        state.copyWith(
          status: status,
          isLoading: false,
          hasChecked: true,
        ),
      );
    } on Exception {
      // If request fails, keep current status but mark as checked
      emit(
        state.copyWith(
          isLoading: false,
          hasChecked: true,
        ),
      );
    }
  }

  /// Opens the app settings page for the user to grant permission.
  ///
  /// Used when permission is permanently denied. Returns true if settings
  /// were opened successfully.
  Future<bool> openSettings() async {
    return _permissionService.openAppSettings();
  }
}
