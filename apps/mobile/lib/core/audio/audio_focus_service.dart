import 'dart:async';
import 'dart:developer' as developer;

import 'package:audio_session/audio_session.dart';

/// Service for managing audio focus and detecting interruptions.
///
/// Wraps the `audio_session` package to detect when audio focus
/// is lost or interrupted (e.g., phone call, backgrounding, etc.).
class AudioFocusService {
  /// Creates an [AudioFocusService].
  ///
  /// Accepts an optional [AudioSession] for testability.
  AudioFocusService({AudioSession? audioSession})
    : _audioSession = audioSession;

  final AudioSession? _audioSession;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  final StreamController<AudioInterruptionEvent> _interruptionController =
      StreamController<AudioInterruptionEvent>.broadcast();

  /// Stream of audio interruption events.
  Stream<AudioInterruptionEvent> get interruptions =>
      _interruptionController.stream;

  /// Initializes the audio session for speech recording.
  ///
  /// Configures the audio session category and begins listening
  /// for interruption events.
  Future<void> initialize() async {
    try {
      final session = _audioSession ?? await AudioSession.instance;

      // Configure for speech recording
      await session.configure(
        const AudioSessionConfiguration.speech(),
      );

      // Cancel existing subscription if any to prevent duplicates
      await _interruptionSubscription?.cancel();

      // Subscribe to interruption events
      _interruptionSubscription = session.interruptionEventStream.listen((
        event,
      ) {
        developer.log(
          'AudioFocusService: interruption detected',
          name: 'AudioFocusService',
          error: {
            'began': event.begin,
            'type': event.type.toString(),
          },
        );
        _interruptionController.add(event);
      });

      developer.log(
        'AudioFocusService initialized',
        name: 'AudioFocusService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'AudioFocusService initialization failed',
        name: 'AudioFocusService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Disposes the service and cancels subscriptions.
  Future<void> dispose() async {
    await _interruptionSubscription?.cancel();
    await _interruptionController.close();
    developer.log(
      'AudioFocusService disposed',
      name: 'AudioFocusService',
    );
  }
}
