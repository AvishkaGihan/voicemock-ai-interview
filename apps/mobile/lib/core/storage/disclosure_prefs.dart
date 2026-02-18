import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's disclosure acknowledgment using [SharedPreferences].
///
/// Uses a versioned key (`disclosure_acknowledged_v1`) so that future
/// disclosure updates can re-trigger the banner without manual data migration.
class DisclosurePrefs {
  DisclosurePrefs(this._prefs);

  final SharedPreferences _prefs;

  /// Versioned key — increment suffix when disclosure copy changes materially.
  static const String _kAcknowledgedKey = 'disclosure_acknowledged_v1';

  /// Returns `true` if the user has previously acknowledged the disclosure.
  Future<bool> hasAcknowledgedDisclosure() async {
    return _prefs.getBool(_kAcknowledgedKey) ?? false;
  }

  /// Persists the acknowledgment so the banner is not shown again.
  Future<void> acknowledgeDisclosure() async {
    await _prefs.setBool(_kAcknowledgedKey, true);
  }
}
