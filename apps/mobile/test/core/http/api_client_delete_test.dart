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

class DeleteData {
  DeleteData({required this.deleted});

  factory DeleteData.fromJson(Map<String, dynamic> json) {
    return DeleteData(deleted: json['deleted'] as bool);
  }

  final bool deleted;
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

  group('ApiClient.delete', () {
    test('parses envelope successfully', () async {
      fakeHeaders.add('x-request-id', 'request-1');
      when(() => mockResponse.headers).thenReturn(fakeHeaders);
      when(() => mockResponse.data).thenReturn({
        'data': {'deleted': true},
        'error': null,
        'request_id': 'request-1',
      });

      when(
        () => mockDio.delete<dynamic>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final apiClient = ApiClient.withDio(mockDio);
      final result = await apiClient.delete<DeleteData>(
        '/session/abc',
        fromJson: DeleteData.fromJson,
        bearerToken: 'token-123',
        timeout: const Duration(seconds: 30),
      );

      expect(result.data?.deleted, isTrue);

      final captured = verify(
        () => mockDio.delete<dynamic>(
          '/session/abc',
          options: captureAny(named: 'options'),
        ),
      ).captured;

      final options = captured.single as Options;
      expect(options.headers?['Authorization'], 'Bearer token-123');
      expect(options.receiveTimeout, const Duration(seconds: 30));
      expect(options.sendTimeout, const Duration(seconds: 30));
    });

    test('throws ServerException when envelope has error', () async {
      fakeHeaders.add('x-request-id', 'request-2');
      when(() => mockResponse.headers).thenReturn(fakeHeaders);
      when(() => mockResponse.data).thenReturn({
        'data': null,
        'error': {
          'stage': 'unknown',
          'code': 'session_not_found',
          'message_safe': 'Session not found or already deleted.',
          'retryable': false,
        },
        'request_id': 'request-2',
      });

      when(
        () => mockDio.delete<dynamic>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final apiClient = ApiClient.withDio(mockDio);

      expect(
        () => apiClient.delete<DeleteData>(
          '/session/missing',
          fromJson: DeleteData.fromJson,
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'session_not_found',
          ),
        ),
      );
    });
  });
}
