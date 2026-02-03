import 'package:equatable/equatable.dart';
import 'package:voicemock/core/permissions/permission_service.dart';

/// State for the permission Cubit.
///
/// Tracks the current microphone permission status and loading state.
class PermissionState extends Equatable {
  const PermissionState({
    required this.status,
    this.isLoading = false,
    this.hasChecked = false,
  });

  /// Creates initial state with unknown status.
  factory PermissionState.initial() {
    return const PermissionState(
      status: MicrophonePermissionStatus.denied,
    );
  }

  /// The current microphone permission status.
  final MicrophonePermissionStatus status;

  /// Whether a permission operation is in progress.
  final bool isLoading;

  /// Whether the permission has been checked at least once.
  final bool hasChecked;

  /// Whether the microphone permission is granted.
  bool get isGranted => status == MicrophonePermissionStatus.granted;

  /// Whether the permission is denied but can be requested again.
  bool get isDenied => status == MicrophonePermissionStatus.denied;

  /// Whether the permission is permanently denied.
  bool get isPermanentlyDenied =>
      status == MicrophonePermissionStatus.permanentlyDenied;

  /// Whether the permission is restricted by system policies.
  bool get isRestricted => status == MicrophonePermissionStatus.restricted;

  /// Creates a copy with the specified changes.
  PermissionState copyWith({
    MicrophonePermissionStatus? status,
    bool? isLoading,
    bool? hasChecked,
  }) {
    return PermissionState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      hasChecked: hasChecked ?? this.hasChecked,
    );
  }

  @override
  List<Object?> get props => [status, isLoading, hasChecked];
}
