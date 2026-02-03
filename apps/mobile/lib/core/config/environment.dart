/// Environment configuration for different deployment flavors.
abstract class Environment {
  /// Development environment (local backend).
  /// Android emulator uses 10.0.2.2 to access host machine's localhost.
  static const String development = 'http://10.0.2.2:8000';

  /// Staging environment.
  static const String staging = 'https://voicemock-staging.onrender.com';

  /// Production environment.
  static const String production = 'https://voicemock.onrender.com';

  /// Current environment base URL (defaults to development).
}
