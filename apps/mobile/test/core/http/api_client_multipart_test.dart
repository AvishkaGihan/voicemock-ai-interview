import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/http/api_client.dart';
import 'package:voicemock/core/http/exceptions.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response<dynamic> {}

class FakeRequestOptions extends Fake implements RequestOptions {
  @override
  StackTrace? get sourceStackTrace => null;
}

class FakeHeaders extends Fake implements Headers {
  final Map<String, List<String>> _map = {};

  @override
  String? value(String name) {
    final values = _map[name.toLowerCase()];
    return values?.isNotEmpty ?? false ? values!.first : null;
  }

  @override
  void add(String name, String value) {
    _map[name.toLowerCase()] = [value];
  }
}

// Test model for fromJson
class TestData {
  TestData({required this.message});

  factory TestData.fromJson(Map<String, dynamic> json) {
    return TestData(message: json['message'] as String);
  }

  final String message;
}

void main() {
  late MockDio mockDio;
  late MockResponse mockResponse;
  late FakeHeaders fakeHeaders;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    mockResponse = MockResponse();
    fakeHeaders = FakeHeaders();
  });

  group('ApiClient.postMultipart', () {
    test('should construct FormData with file and fields correctly', () async {
      // Create a temporary test file
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      fakeHeaders.add('x-request-id', 'test-request-id');

      // Success response envelope
      when(() => mockResponse.headers).thenReturn(fakeHeaders);
      when(() => mockResponse.data).thenReturn({
        'data': {'message': 'Success'},
        'error': null,
        'request_id': 'test-request-id',
      });

      when(
        () => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final apiClient = ApiClient.withDio(mockDio);

      final result = await apiClient.postMultipart<TestData>(
        '/turn',
        filePath: testFile.path,
        fileFieldName: 'audio',
        fields: {'session_id': 'test-session-123'},
        bearerToken: 'test_token',
        fromJson: TestData.fromJson,
      );

      expect(result.data?.message, 'Success');

      // Verify Dio.post was called
      final captured = verify(
        () => mockDio.post<dynamic>(
          '/turn',
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      // Verify FormData structure
      expect(captured[0], isA<FormData>());
      final formData = captured[0] as FormData;
      expect(formData.fields.length, greaterThanOrEqualTo(1));
      expect(
        formData.fields.any((field) => field.key == 'session_id'),
        isTrue,
      );

      // Verify Options include Bearer token
      final options = captured[1] as Options;
      expect(options.headers?['Authorization'], 'Bearer test_token');
      expect(
        options.receiveTimeout,
        const Duration(seconds: 60),
      );
    });

    test('should set Authorization header with Bearer token', () async {
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      fakeHeaders.add('x-request-id', 'test-request-id');

      when(() => mockResponse.headers).thenReturn(fakeHeaders);
      when(() => mockResponse.data).thenReturn({
        'data': {'message': 'Success'},
        'error': null,
        'request_id': 'test-request-id',
      });

      when(
        () => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final apiClient = ApiClient.withDio(mockDio);

      await apiClient.postMultipart<TestData>(
        '/turn',
        filePath: testFile.path,
        fileFieldName: 'audio',
        fields: {'session_id': 'test-session-123'},
        bearerToken: 'my_secret_token',
        fromJson: TestData.fromJson,
      );

      final captured = verify(
        () => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      final options = captured.last as Options;
      expect(options.headers?['Authorization'], 'Bearer my_secret_token');
    });

    test('should parse error response from multipart endpoint', () async {
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      fakeHeaders.add('x-request-id', 'test-request-id');

      // Error response envelope
      when(() => mockResponse.headers).thenReturn(fakeHeaders);
      when(() => mockResponse.data).thenReturn({
        'data': null,
        'error': {
          'stage': 'stt',
          'code': 'stt_timeout',
          'message_safe': 'Transcription timed out',
          'retryable': true,
        },
        'request_id': 'test-request-id',
      });

      when(
        () => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final apiClient = ApiClient.withDio(mockDio);

      expect(
        () => apiClient.postMultipart<TestData>(
          '/turn',
          filePath: testFile.path,
          fileFieldName: 'audio',
          fields: {'session_id': 'test-session-123'},
          bearerToken: 'test_token',
          fromJson: TestData.fromJson,
        ),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'stt_timeout')
              .having((e) => e.stage, 'stage', 'stt')
              .having((e) => e.retryable, 'retryable', true),
        ),
      );
    });

    test('should handle network timeout', () async {
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      when(
        () => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: FakeRequestOptions(),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final apiClient = ApiClient.withDio(mockDio);

      expect(
        () => apiClient.postMultipart<TestData>(
          '/turn',
          filePath: testFile.path,
          fileFieldName: 'audio',
          fields: {'session_id': 'test-session-123'},
          fromJson: TestData.fromJson,
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should set session_id as form field', () async {
      final testFile = File('test_audio.webm')..writeAsStringSync('fake_audio');
      addTearDown(testFile.deleteSync);

      fakeHeaders.add('x-request-id', 'test-request-id');

      when(() => mockResponse.headers).thenReturn(fakeHeaders);
      when(() => mockResponse.data).thenReturn({
        'data': {'message': 'Success'},
        'error': null,
        'request_id': 'test-request-id',
      });

      when(
        () => mockDio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final apiClient = ApiClient.withDio(mockDio);

      await apiClient.postMultipart<TestData>(
        '/turn',
        filePath: testFile.path,
        fileFieldName: 'audio',
        fields: {'session_id': 'my-session-id'},
        fromJson: TestData.fromJson,
      );

      final captured = verify(
        () => mockDio.post<dynamic>(
          any(),
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured;

      final formData = captured.first as FormData;
      final sessionIdField = formData.fields.firstWhere(
        (field) => field.key == 'session_id',
      );
      expect(sessionIdField.value, 'my-session-id');
    });
  });
}
