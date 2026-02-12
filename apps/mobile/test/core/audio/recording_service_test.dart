import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:voicemock/core/audio/recording_service.dart';

class MockAudioRecorder extends Mock implements AudioRecorder {}

class FakeRecordConfig extends Fake implements RecordConfig {}

class FakeDirectory extends Fake implements Directory {
  @override
  String get path => '/tmp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeRecordConfig());
  });

  group('RecordingService', () {
    late AudioRecorder mockRecorder;
    late RecordingService recordingService;

    Future<Directory> mockPathProvider() async => FakeDirectory();

    setUp(() {
      mockRecorder = MockAudioRecorder();
      recordingService = RecordingService(
        recorder: mockRecorder,
        pathProvider: mockPathProvider,
      );
    });

    group('startRecording', () {
      test('calls AudioRecorder.start with correct config', () async {
        // Arrange
        when(
          () => mockRecorder.start(
            any(),
            path: any(named: 'path'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await recordingService.startRecording();

        // Assert
        final captured = verify(
          () => mockRecorder.start(
            captureAny(),
            path: captureAny(named: 'path'),
          ),
        ).captured;

        final config = captured[0] as RecordConfig;
        expect(config.encoder, AudioEncoder.aacLc);
        expect(config.sampleRate, 44100);
        expect(config.bitRate, 128000);

        final path = captured[1] as String;
        expect(path, contains('voicemock_turn_'));
        expect(path, endsWith('.m4a'));
      });

      test('throws exception when start fails', () async {
        // Arrange
        when(
          () => mockRecorder.start(
            any(),
            path: any(named: 'path'),
          ),
        ).thenThrow(Exception('Failed to start recording'));

        // Act & Assert
        expect(
          () => recordingService.startRecording(),
          throwsException,
        );
      });
    });

    group('stopRecording', () {
      test('calls AudioRecorder.stop and returns file path', () async {
        // Arrange
        const expectedPath = '/tmp/voicemock_turn_123456.m4a';
        when(() => mockRecorder.stop()).thenAnswer((_) async => expectedPath);

        // Act
        final result = await recordingService.stopRecording();

        // Assert
        verify(() => mockRecorder.stop()).called(1);
        expect(result, expectedPath);
      });

      test('returns null when stop returns null', () async {
        // Arrange
        when(() => mockRecorder.stop()).thenAnswer((_) async => null);

        // Act
        final result = await recordingService.stopRecording();

        // Assert
        expect(result, isNull);
      });

      test('throws exception when stop fails', () async {
        // Arrange
        when(
          () => mockRecorder.stop(),
        ).thenThrow(Exception('Failed to stop recording'));

        // Act & Assert
        expect(
          () => recordingService.stopRecording(),
          throwsException,
        );
      });
    });

    group('isRecording', () {
      test('returns correct recording state', () async {
        // Arrange
        when(() => mockRecorder.isRecording()).thenAnswer((_) async => true);

        // Act
        final result = await recordingService.isRecording;

        // Assert
        verify(() => mockRecorder.isRecording()).called(1);
        expect(result, isTrue);
      });

      test('returns false when not recording', () async {
        // Arrange
        when(() => mockRecorder.isRecording()).thenAnswer((_) async => false);

        // Act
        final result = await recordingService.isRecording;

        // Assert
        expect(result, isFalse);
      });
    });

    group('dispose', () {
      test('calls AudioRecorder.dispose', () async {
        // Arrange
        when(() => mockRecorder.dispose()).thenAnswer((_) async {});

        // Act
        await recordingService.dispose();

        // Assert
        verify(() => mockRecorder.dispose()).called(1);
      });
    });
    group('deleteRecording', () {
      test('deletes file if it exists', () async {
        // Create a real temp file for testing
        final tempDir = Directory.systemTemp.createTempSync();
        final file = File('${tempDir.path}/test_recording.m4a')..createSync();

        expect(file.existsSync(), isTrue);

        await recordingService.deleteRecording(file.path);

        expect(file.existsSync(), isFalse);
        tempDir.deleteSync();
      });

      test('does nothing if file does not exist', () async {
        // Just verify it doesn't throw
        final tempDir = Directory.systemTemp.createTempSync();
        final path = '${tempDir.path}/non_existent.m4a';

        expect(File(path).existsSync(), isFalse);

        await recordingService.deleteRecording(path);
        tempDir.deleteSync();
      });
    });
  });
}
