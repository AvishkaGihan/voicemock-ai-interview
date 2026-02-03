import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voicemock/features/interview/domain/session.dart';

/// Local data source for persisting session credentials.
class SessionLocalDataSource {
  SessionLocalDataSource({
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  }) : _prefs = prefs,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _keySessionId = 'session_id';
  static const _keySessionToken = 'session_token';
  static const _keyOpeningPrompt = 'opening_prompt';
  static const _keyCreatedAt = 'created_at';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  AndroidOptions get _androidOptions => AndroidOptions.defaultOptions;

  /// Saves session credentials locally.
  Future<void> saveSession(Session session) async {
    await Future.wait([
      _secureStorage.write(
        key: _keySessionId,
        value: session.sessionId,
        aOptions: _androidOptions,
      ),
      _secureStorage.write(
        key: _keySessionToken,
        value: session.sessionToken,
        aOptions: _androidOptions,
      ),
      _prefs.setString(_keyOpeningPrompt, session.openingPrompt),
      _prefs.setString(
        _keyCreatedAt,
        session.createdAt.toIso8601String(),
      ),
    ]);
  }

  /// Retrieves stored session or null if none exists.
  Future<Session?> getSession() async {
    final sessionId = await _secureStorage.read(
      key: _keySessionId,
      aOptions: _androidOptions,
    );
    final sessionToken = await _secureStorage.read(
      key: _keySessionToken,
      aOptions: _androidOptions,
    );
    final openingPrompt = _prefs.getString(_keyOpeningPrompt);
    final createdAtStr = _prefs.getString(_keyCreatedAt);

    if (sessionId == null ||
        sessionToken == null ||
        openingPrompt == null ||
        createdAtStr == null) {
      return null;
    }

    return Session(
      sessionId: sessionId,
      sessionToken: sessionToken,
      openingPrompt: openingPrompt,
      createdAt: DateTime.parse(createdAtStr),
    );
  }

  /// Clears stored session credentials.
  Future<void> clearSession() async {
    await Future.wait([
      _secureStorage.delete(
        key: _keySessionId,
        aOptions: _androidOptions,
      ),
      _secureStorage.delete(
        key: _keySessionToken,
        aOptions: _androidOptions,
      ),
      _prefs.remove(_keyOpeningPrompt),
      _prefs.remove(_keyCreatedAt),
    ]);
  }
}
