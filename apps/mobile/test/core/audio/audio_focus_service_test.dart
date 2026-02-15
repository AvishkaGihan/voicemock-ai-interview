import 'dart:async' show StreamController, unawaited;

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/audio/audio_focus_service.dart';

class MockAudioSession extends Mock implements AudioSession {}

void main() {
  group('AudioFocusService', () {
    late MockAudioSession mockAudioSession;
    late StreamController<AudioInterruptionEvent> interruptionController;

    setUp(() {
      mockAudioSession = MockAudioSession();
      interruptionController =
          StreamController<AudioInterruptionEvent>.broadcast();

      when(
        () => mockAudioSession.interruptionEventStream,
      ).thenAnswer((_) => interruptionController.stream);
      when(
        () => mockAudioSession.configure(
          const AudioSessionConfiguration.speech(),
        ),
      ).thenAnswer((_) async => true);
    });

    tearDown(() {
      unawaited(interruptionController.close());
    });

    test('initialize configures audio session correctly', () async {
      final service = AudioFocusService(audioSession: mockAudioSession);

      await service.initialize();

      verify(
        () => mockAudioSession.configure(
          const AudioSessionConfiguration.speech(),
        ),
      ).called(1);
    });

    test('interruption events are forwarded via the stream', () async {
      final service = AudioFocusService(audioSession: mockAudioSession);
      await service.initialize();

      final interruptions = <AudioInterruptionEvent>[];
      final subscription = service.interruptions.listen(interruptions.add);

      // Simulate interruption event
      final interruptionEvent = AudioInterruptionEvent(
        true, // begin
        AudioInterruptionType.unknown,
      );
      interruptionController.add(interruptionEvent);

      await Future<void>.delayed(Duration.zero); // Let stream propagate

      expect(interruptions, hasLength(1));
      expect(interruptions.first.begin, true);
      expect(interruptions.first.type, AudioInterruptionType.unknown);

      await subscription.cancel();
      await service.dispose();
    });

    test('dispose cancels subscriptions', () async {
      final service = AudioFocusService(audioSession: mockAudioSession);
      await service.initialize();

      // Add a listener to verify stream can receive events
      final interruptions = <AudioInterruptionEvent>[];
      final subscription = service.interruptions.listen(interruptions.add);

      await service.dispose();
      await subscription.cancel();

      // After dispose, the internal controller should be closed
      // We can't directly test this, but we can verify no crash occurs
      await service.dispose();
    });

    test('multiple interruptions are forwarded correctly', () async {
      final service = AudioFocusService(audioSession: mockAudioSession);
      await service.initialize();

      final interruptions = <AudioInterruptionEvent>[];
      final subscription = service.interruptions.listen(interruptions.add);

      // Simulate multiple interruption events
      final event1 = AudioInterruptionEvent(
        true, // begin
        AudioInterruptionType.unknown,
      );
      final event2 = AudioInterruptionEvent(
        false, // begin
        AudioInterruptionType.unknown,
      );

      interruptionController
        ..add(event1)
        ..add(event2);

      await Future<void>.delayed(Duration.zero);

      expect(interruptions.length, 2);
      expect(interruptions[0].begin, true);
      expect(interruptions[1].begin, false);

      await subscription.cancel();
      await service.dispose();
    });
  });
}
