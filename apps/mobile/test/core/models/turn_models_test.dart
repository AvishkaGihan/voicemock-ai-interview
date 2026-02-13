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
      };

      final result = TurnResponseData.fromJson(json);

      expect(result.transcript, 'Hello world');
      expect(result.assistantText, null);
      expect(result.ttsAudioUrl, null);
      expect(result.timings['stt_ms'], 820.3);
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
      );

      final json = data.toJson();

      expect(json['transcript'], 'Test transcript');
      expect(json['assistant_text'], 'Test response');
      expect(json['tts_audio_url'], 'https://example.com/test.mp3');
      expect(json['timings'], {
        'upload_ms': 100.0,
        'stt_ms': 500.0,
        'total_ms': 600.0,
      });
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'transcript': 'Test',
        'timings': <String, dynamic>{},
      };

      final result = TurnResponseData.fromJson(json);

      expect(result.transcript, 'Test');
      expect(result.assistantText, null);
      expect(result.ttsAudioUrl, null);
      expect(result.timings, <String, dynamic>{});
    });
  });
}
