/// Microphone permission status values.
///
/// Represents all possible states of microphone permission.
enum MicrophonePermissionStatus {
  /// Permission has been granted by the user.
  granted,

  /// Permission has been denied by the user.
  denied,

  /// Permission has been permanently denied (user selected "Don't ask again").
  /// Requires opening app settings to change.
  permanentlyDenied,

  /// Permission is restricted by system policies (parental controls, etc.).
  restricted,

  /// Permission is granted with limited access (iOS-specific).
  limited,
}

/// Abstract interface for permission services.
///
/// Defines the contract for checking and requesting permissions.
/// This abstraction allows for easy testing and platform-specific
/// implementations.
abstract class PermissionService {
  /// Checks the current permission status without prompting the user.
  Future<MicrophonePermissionStatus> checkMicrophonePermission();

  /// Requests permission from the user.
  ///
  /// Shows the system permission dialog. Returns the resulting status.
  Future<MicrophonePermissionStatus> requestMicrophonePermission();

  /// Opens the app settings page.
  ///
  /// Used when permission is permanently denied to allow user to enable it.
  /// Returns true if settings were opened successfully.
  Future<bool> openAppSettings();
}
