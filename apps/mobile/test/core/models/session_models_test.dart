import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/models/session_models.dart';

void main() {
  group('SessionStartRequest', () {
    test('toJson converts to snake_case correctly', () {
      const request = SessionStartRequest(
        role: 'Software Engineer',
        interviewType: 'behavioral',
        difficulty: 'medium',
        questionCount: 5,
      );

      final json = request.toJson();

      expect(json['role'], 'Software Engineer');
      expect(json['interview_type'], 'behavioral');
      expect(json['difficulty'], 'medium');
      expect(json['question_count'], 5);
      expect(json.containsKey('interviewType'), isFalse);
      expect(json.containsKey('questionCount'), isFalse);
    });

    test('includes all required fields', () {
      const request = SessionStartRequest(
        role: 'Product Manager',
        interviewType: 'technical',
        difficulty: 'hard',
        questionCount: 10,
      );

      final json = request.toJson();

      expect(json.keys, hasLength(4));
      expect(json.containsKey('role'), isTrue);
      expect(json.containsKey('interview_type'), isTrue);
      expect(json.containsKey('difficulty'), isTrue);
      expect(json.containsKey('question_count'), isTrue);
    });
  });

  group('SessionStartResponse', () {
    test('fromJson parses snake_case correctly', () {
      final json = {
        'session_id': 'session-123',
        'session_token': 'token-abc',
        'opening_prompt': 'Welcome to the interview!',
      };

      final response = SessionStartResponse.fromJson(json);

      expect(response.sessionId, 'session-123');
      expect(response.sessionToken, 'token-abc');
      expect(response.openingPrompt, 'Welcome to the interview!');
    });

    test('includes all required fields', () {
      final json = {
        'session_id': 'test-id',
        'session_token': 'test-token',
        'opening_prompt': 'Test prompt',
      };

      final response = SessionStartResponse.fromJson(json);

      expect(response.sessionId, isNotEmpty);
      expect(response.sessionToken, isNotEmpty);
      expect(response.openingPrompt, isNotEmpty);
    });
  });
}
