/// Environment configuration for different deployment flavors.
abstract class Environment {
  /// Development environment (local backend).
  /// For physical device, use host machine's IP address (e.g., 192.168.54.52).
  /// Android emulator uses 10.0.2.2 to access host machine's localhost.
  static const String development = 'http://192.168.54.52:8000';

  /// Staging environment.
  static const String staging = 'https://voicemock-staging.onrender.com';

  /// Production environment.
  static const String production = 'https://voicemock.onrender.com';

  /// Current environment base URL (defaults to development).
}
