import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/http/api_client.dart';
import 'package:voicemock/core/http/exceptions.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/features/interview/data/datasources/turn_remote_data_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TurnRemoteDataSource dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = TurnRemoteDataSource(mockApiClient);
  });

  group('TurnRemoteDataSource', () {
    test('should call postMultipart with correct parameters', () async {
      // Create a temporary test file
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      const mockEnvelope = ApiEnvelope<TurnResponseData>(
        data: TurnResponseData(
          transcript: 'Hello world',
          timings: {'stt_ms': 820.5, 'total_ms': 940.8},
          questionNumber: 1,
          totalQuestions: 5,
        ),
        error: null,
        requestId: 'test-request-id',
      );

      when(
        () => mockApiClient.postMultipart<TurnResponseData>(
          any(),
          filePath: any(named: 'filePath'),
          fileFieldName: any(named: 'fileFieldName'),
          fields: any(named: 'fields'),
          bearerToken: any(named: 'bearerToken'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((_) async => mockEnvelope);

      final result = await dataSource.submitTurn(
        audioPath: testFile.path,
        sessionId: 'test-session-123',
        sessionToken: 'test_token',
      );

      expect(result.transcript, 'Hello world');
      expect(result.timings['stt_ms'], 820.5);

      verify(
        () => mockApiClient.postMultipart<TurnResponseData>(
          '/turn',
          filePath: testFile.path,
          fileFieldName: 'audio',
          fields: {'session_id': 'test-session-123'},
          bearerToken: 'test_token',
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });

    test('should call postMultipart for transcript retry', () async {
      const mockEnvelope = ApiEnvelope<TurnResponseData>(
        data: TurnResponseData(
          transcript: 'Existing transcript',
          timings: {'llm_ms': 500.0, 'total_ms': 500.0},
          questionNumber: 1,
          totalQuestions: 5,
        ),
        error: null,
        requestId: 'test-request-id',
      );

      when(
        () => mockApiClient.postMultipart<TurnResponseData>(
          any(),
          // filePath/fileFieldName should be null/not provided or null
          filePath: any(named: 'filePath'),
          fileFieldName: any(named: 'fileFieldName'),
          fields: any(named: 'fields'),
          bearerToken: any(named: 'bearerToken'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((_) async => mockEnvelope);

      final result = await dataSource.submitTurn(
        transcript: 'Existing transcript',
        sessionId: 'test-session-123',
        sessionToken: 'test_token',
      );

      expect(result.transcript, 'Existing transcript');

      verify(
        () => mockApiClient.postMultipart<TurnResponseData>(
          '/turn',
          fields: {
            'session_id': 'test-session-123',
            'transcript': 'Existing transcript',
          },
          bearerToken: 'test_token',
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });

    test('should return unwrapped TurnResponseData from envelope', () async {
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      const expectedData = TurnResponseData(
        transcript: 'Test transcript',
        timings: {'upload_ms': 100.0, 'stt_ms': 500.0, 'total_ms': 600.0},
        questionNumber: 1,
        totalQuestions: 5,
      );

      const mockEnvelope = ApiEnvelope<TurnResponseData>(
        data: expectedData,
        error: null,
        requestId: 'test-request-id',
      );

      when(
        () => mockApiClient.postMultipart<TurnResponseData>(
          any(),
          filePath: any(named: 'filePath'),
          fileFieldName: any(named: 'fileFieldName'),
          fields: any(named: 'fields'),
          bearerToken: any(named: 'bearerToken'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((_) async => mockEnvelope);

      final result = await dataSource.submitTurn(
        audioPath: testFile.path,
        sessionId: 'session-123',
        sessionToken: 'token',
      );

      expect(result, expectedData);
    });

    test('should propagate ServerException from ApiClient', () async {
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      when(
        () => mockApiClient.postMultipart<TurnResponseData>(
          any(),
          filePath: any(named: 'filePath'),
          fileFieldName: any(named: 'fileFieldName'),
          fields: any(named: 'fields'),
          bearerToken: any(named: 'bearerToken'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenThrow(
        ServerException(
          message: 'Transcription timed out',
          code: 'stt_timeout',
          stage: 'stt',
          retryable: true,
        ),
      );

      expect(
        () => dataSource.submitTurn(
          audioPath: testFile.path,
          sessionId: 'session-123',
          sessionToken: 'token',
        ),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'stt_timeout')
              .having((e) => e.stage, 'stage', 'stt')
              .having((e) => e.retryable, 'retryable', true),
        ),
      );
    });

    test('should propagate NetworkException from ApiClient', () async {
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      when(
        () => mockApiClient.postMultipart<TurnResponseData>(
          any(),
          filePath: any(named: 'filePath'),
          fileFieldName: any(named: 'fileFieldName'),
          fields: any(named: 'fields'),
          bearerToken: any(named: 'bearerToken'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenThrow(NetworkException(message: 'Network timeout'));

      expect(
        () => dataSource.submitTurn(
          audioPath: testFile.path,
          sessionId: 'session-123',
          sessionToken: 'token',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
