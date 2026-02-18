import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/audio/playback_service.dart';

class MockAudioPlayer extends Mock implements ja.AudioPlayer {}

class FakeAudioSource extends Fake implements ja.AudioSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(FakeAudioSource());
  });

  group('PlaybackService', () {
    late MockAudioPlayer mockAudioPlayer;
    late StreamController<ja.PlayerState> playerStateController;
    late StreamController<ja.PlaybackEvent> playbackEventController;
    late PlaybackService service;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();
      playerStateController = StreamController<ja.PlayerState>.broadcast();
      playbackEventController = StreamController<ja.PlaybackEvent>.broadcast();

      when(
        () => mockAudioPlayer.playerStateStream,
      ).thenAnswer((_) => playerStateController.stream);
      when(
        () => mockAudioPlayer.playbackEventStream,
      ).thenAnswer((_) => playbackEventController.stream);
      when(() => mockAudioPlayer.playing).thenReturn(false);
      when(
        () => mockAudioPlayer.processingState,
      ).thenReturn(ja.ProcessingState.idle);
      when(() => mockAudioPlayer.stop()).thenAnswer((_) async {});
      when(() => mockAudioPlayer.pause()).thenAnswer((_) async {});
      when(
        () => mockAudioPlayer.setAudioSource(any()),
      ).thenAnswer((_) async => null);
      when(() => mockAudioPlayer.play()).thenAnswer((_) async {});
      when(() => mockAudioPlayer.dispose()).thenAnswer((_) async {});

      service = PlaybackService(audioPlayer: mockAudioPlayer);
    });

    tearDown(() async {
      await service.dispose();
      await playerStateController.close();
      await playbackEventController.close();
    });

    test('playUrl starts playback', () async {
      await service.playUrl('https://example.com/tts/req-1');

      verifyInOrder([
        () => mockAudioPlayer.stop(),
        () => mockAudioPlayer.setAudioSource(any()),
        () => mockAudioPlayer.play(),
      ]);
    });

    test('stop stops playback', () async {
      await service.stop();

      verify(() => mockAudioPlayer.stop()).called(1);
    });

    test(
      'playUrl while already playing stops previous playback first',
      () async {
        await service.playUrl('https://example.com/tts/req-1');
        await service.playUrl('https://example.com/tts/req-2');

        verify(() => mockAudioPlayer.stop()).called(greaterThanOrEqualTo(2));
      },
    );

    test('completion event is emitted when playback finishes', () async {
      final events = <PlaybackEvent>[];
      final subscription = service.events.listen(events.add);

      await service.playUrl('https://example.com/tts/req-1');
      playerStateController.add(
        ja.PlayerState(false, ja.ProcessingState.completed),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.any((event) => event is PlaybackCompleted), isTrue);
      await subscription.cancel();
    });

    test('error event is emitted on failure', () async {
      final events = <PlaybackEvent>[];
      final subscription = service.events.listen(events.add);

      when(
        () => mockAudioPlayer.setAudioSource(any()),
      ).thenThrow(Exception('decode failed'));

      await expectLater(
        service.playUrl('https://example.com/tts/req-1'),
        throwsA(isA<Exception>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.any((event) => event is PlaybackError), isTrue);
      await subscription.cancel();
    });

    test('dispose releases resources', () async {
      await service.dispose();

      verify(() => mockAudioPlayer.dispose()).called(1);
    });

    test('pause pauses playback and emits PlaybackPaused', () async {
      final events = <PlaybackEvent>[];
      final subscription = service.events.listen(events.add);

      await service.pause();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(() => mockAudioPlayer.pause()).called(1);
      expect(events.any((event) => event is PlaybackPaused), isTrue);
      await subscription.cancel();
    });

    test('resume resumes playback and emits PlaybackPlaying', () async {
      final events = <PlaybackEvent>[];
      final subscription = service.events.listen(events.add);

      await service.resume();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(() => mockAudioPlayer.play()).called(1);
      expect(events.any((event) => event is PlaybackPlaying), isTrue);
      await subscription.cancel();
    });

    test('isPaused returns true when paused and not idle/completed', () {
      when(() => mockAudioPlayer.playing).thenReturn(false);
      when(
        () => mockAudioPlayer.processingState,
      ).thenReturn(ja.ProcessingState.ready);

      expect(service.isPaused, isTrue);
    });

    test('isPaused returns false when idle', () {
      when(() => mockAudioPlayer.playing).thenReturn(false);
      when(
        () => mockAudioPlayer.processingState,
      ).thenReturn(ja.ProcessingState.idle);

      expect(service.isPaused, isFalse);
    });

    test('pause is no-op in noop mode', () async {
      final noopService = PlaybackService.noop();

      await noopService.pause();

      verifyNever(() => mockAudioPlayer.pause());
      await noopService.dispose();
    });

    test('resume is no-op in noop mode', () async {
      final noopService = PlaybackService.noop();

      await noopService.resume();

      verifyNever(() => mockAudioPlayer.play());
      await noopService.dispose();
    });
  });
}
