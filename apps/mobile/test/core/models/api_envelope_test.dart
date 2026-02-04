import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/models/api_envelope.dart';

void main() {
  group('ApiEnvelope', () {
    test('fromJson parses success response correctly', () {
      final json = {
        'data': {'test': 'value'},
        'error': null,
        'request_id': 'req-123',
      };

      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        json,
        (data) => data! as Map<String, dynamic>,
      );

      expect(envelope.data, {'test': 'value'});
      expect(envelope.error, isNull);
      expect(envelope.requestId, 'req-123');
      expect(envelope.isSuccess, isTrue);
      expect(envelope.isError, isFalse);
    });

    test('fromJson parses error response correctly', () {
      final json = {
        'data': null,
        'error': {
          'code': 'validation_error',
          'stage': 'unknown',
          'message_safe': 'Invalid input',
          'retryable': false,
          'details': {'field': 'difficulty'},
        },
        'request_id': 'req-456',
      };

      final envelope = ApiEnvelope<dynamic>.fromJson(
        json,
        (data) => data,
      );

      expect(envelope.data, isNull);
      expect(envelope.error, isNotNull);
      expect(envelope.error!.code, 'validation_error');
      expect(envelope.error!.messageSafe, 'Invalid input');
      expect(envelope.requestId, 'req-456');
      expect(envelope.isSuccess, isFalse);
      expect(envelope.isError, isTrue);
    });

    test('mutual exclusion of data and error fields', () {
      final successJson = {
        'data': {'key': 'value'},
        'error': null,
        'request_id': 'req-789',
      };

      final successEnvelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        successJson,
        (data) => data! as Map<String, dynamic>,
      );

      expect(successEnvelope.data, isNotNull);
      expect(successEnvelope.error, isNull);
      expect(successEnvelope.isSuccess, isTrue);

      final errorJson = {
        'data': null,
        'error': {
          'code': 'server_error',
          'stage': 'llm',
          'message_safe': 'Something went wrong',
        },
        'request_id': 'req-999',
      };

      final errorEnvelope = ApiEnvelope<dynamic>.fromJson(
        errorJson,
        (data) => data,
      );

      expect(errorEnvelope.data, isNull);
      expect(errorEnvelope.error, isNotNull);
      expect(errorEnvelope.isError, isTrue);
    });
  });

  group('ApiError', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'code': 'network_error',
        'stage': 'upload',
        'message_safe': 'Connection failed',
        'retryable': true,
        'details': {'reason': 'timeout'},
      };

      final error = ApiError.fromJson(json);

      expect(error.code, 'network_error');
      expect(error.stage, 'upload');
      expect(error.messageSafe, 'Connection failed');
      expect(error.retryable, isTrue);
      expect(error.details, {'reason': 'timeout'});
    });

    test('fromJson handles optional fields', () {
      final json = {
        'code': 'internal_error',
        'stage': 'unknown',
        'message_safe': 'An error occurred',
      };

      final error = ApiError.fromJson(json);

      expect(error.code, 'internal_error');
      expect(error.stage, 'unknown');
      expect(error.messageSafe, 'An error occurred');
      expect(error.retryable, isNull);
      expect(error.details, isNull);
    });
  });
}
