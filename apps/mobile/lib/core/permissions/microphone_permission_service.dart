import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:voicemock/core/permissions/permission_service.dart';

/// Implementation of [PermissionService] for microphone access.
///
/// Uses the permission_handler package to interact with the
/// underlying platform's permission system.
class MicrophonePermissionService implements PermissionService {
  /// Creates a new [MicrophonePermissionService].
  const MicrophonePermissionService();

  @override
  Future<MicrophonePermissionStatus> checkMicrophonePermission() async {
    final status = await ph.Permission.microphone.status;
    return _mapStatus(status);
  }

  @override
  Future<MicrophonePermissionStatus> requestMicrophonePermission() async {
    final status = await ph.Permission.microphone.request();
    return _mapStatus(status);
  }

  @override
  Future<bool> openAppSettings() async {
    return ph.openAppSettings();
  }

  /// Maps permission_handler's PermissionStatus to our domain enum.
  MicrophonePermissionStatus _mapStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return MicrophonePermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return MicrophonePermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return MicrophonePermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return MicrophonePermissionStatus.restricted;
      case ph.PermissionStatus.limited:
        return MicrophonePermissionStatus.limited;
      case ph.PermissionStatus.provisional:
        // Treat provisional as granted for our purposes
        return MicrophonePermissionStatus.granted;
    }
  }
}
