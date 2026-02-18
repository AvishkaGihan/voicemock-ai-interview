import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/models/models.dart';

void main() {
  group('TurnResponseData', () {
    test('should deserialize from JSON with snake_case fields', () {
      final json = {
        'transcript': 'Hello world',
        'assistant_text': 'Nice to meet you',
        'tts_audio_url': 'https://example.com/audio.mp3',
        'timings': {
          'upload_ms': 120.5,
          'stt_ms': 820.3,
          'total_ms': 940.8,
        },
        'is_complete': false,
        'question_number': 1,
        'total_questions': 5,
      };

      final result = TurnResponseData.fromJson(json);

      expect(result.transcript, 'Hello world');
      expect(result.assistantText, 'Nice to meet you');
      expect(result.ttsAudioUrl, 'https://example.com/audio.mp3');
      expect(result.timings, {
        'upload_ms': 120.5,
        'stt_ms': 820.3,
        'total_ms': 940.8,
      });
      expect(result.isComplete, false);
      expect(result.questionNumber, 1);
      expect(result.totalQuestions, 5);
    });

    test('should deserialize coaching feedback when present', () {
      final json = {
        'transcript': 'Hello world',
        'assistant_text': 'Nice to meet you',
        'tts_audio_url': 'https://example.com/audio.mp3',
        'coaching_feedback': {
          'dimensions': [
            {
              'label': 'Clarity',
              'score': 4,
              'tip': 'Start with your strongest point.',
            },
            {
              'label': 'Relevance',
              'score': 5,
              'tip': 'Tie examples directly to the role.',
            },
          ],
          'summary_tip':
              'Lead with one clear thesis and support it with one metric.',
        },
        'timings': {
          'upload_ms': 120.5,
          'stt_ms': 820.3,
          'total_ms': 940.8,
        },
        'is_complete': false,
        'question_number': 1,
        'total_questions': 5,
      };

      final result = TurnResponseData.fromJson(json);

      expect(result.coachingFeedback, isNotNull);
      expect(result.coachingFeedback!.summaryTip, contains('clear thesis'));
      expect(result.coachingFeedback!.dimensions.first.label, 'Clarity');
      expect(result.coachingFeedback!.dimensions.first.score, 4);
    });

    test('should handle null optional fields', () {
      final json = {
        'transcript': 'Hello world',
        'assistant_text': null,
        'tts_audio_url': null,
        'timings': {
          'stt_ms': 820.3,
          'total_ms': 940.8,
        },
        'is_complete': false,
        'question_number': 1,
        'total_questions': 5,
      };

      final result = TurnResponseData.fromJson(json);

      expect(result.transcript, 'Hello world');
      expect(result.assistantText, null);
      expect(result.ttsAudioUrl, null);
      expect(result.timings['stt_ms'], 820.3);
      expect(result.isComplete, false);
      expect(result.questionNumber, 1);
      expect(result.totalQuestions, 5);
    });

    test('should serialize to JSON with snake_case fields', () {
      const data = TurnResponseData(
        transcript: 'Test transcript',
        assistantText: 'Test response',
        ttsAudioUrl: 'https://example.com/test.mp3',
        timings: {
          'upload_ms': 100.0,
          'stt_ms': 500.0,
          'total_ms': 600.0,
        },
        questionNumber: 2,
        totalQuestions: 5,
      );

      final json = data.toJson();

      expect(json['transcript'], 'Test transcript');
      expect(json['assistant_text'], 'Test response');
      expect(json['tts_audio_url'], 'https://example.com/test.mp3');
      expect(json['coaching_feedback'], isNull);
      expect(json['timings'], {
        'upload_ms': 100.0,
        'stt_ms': 500.0,
        'total_ms': 600.0,
      });
      expect(json['is_complete'], false);
      expect(json['question_number'], 2);
      expect(json['total_questions'], 5);
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'transcript': 'Test',
        'timings': <String, dynamic>{},
        'question_number': 1,
        'total_questions': 3,
      };

      final result = TurnResponseData.fromJson(json);

      expect(result.transcript, 'Test');
      expect(result.assistantText, null);
      expect(result.ttsAudioUrl, null);
      expect(result.coachingFeedback, null);
      expect(result.timings, <String, dynamic>{});
    });
  });
}
