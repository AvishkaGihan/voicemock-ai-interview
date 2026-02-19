/// Unit tests for TurnTimingRecord model.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/models/turn_timing_record.dart';

void main() {
  group('TurnTimingRecord', () {
    test('creates instance with all fields', () {
      final timestamp = DateTime.now();
      final record = TurnTimingRecord(
        turnNumber: 3,
        requestId: 'req-12345',
        uploadMs: 50.5,
        sttMs: 820.3,
        llmMs: 150.7,
        ttsMs: 220.4,
        totalMs: 1021.5,
        timestamp: timestamp,
      );

      expect(record.turnNumber, 3);
      expect(record.requestId, 'req-12345');
      expect(record.uploadMs, 50.5);
      expect(record.sttMs, 820.3);
      expect(record.llmMs, 150.7);
      expect(record.ttsMs, 220.4);
      expect(record.totalMs, 1021.5);
      expect(record.timestamp, timestamp);
    });

    test('creates instance from TurnResponseData timings', () {
      final timings = <String, double>{
        'upload_ms': 45.2,
        'stt_ms': 780.5,
        'llm_ms': 160.3,
        'tts_ms': 240.6,
        'total_ms': 985.0,
      };
      final timestamp = DateTime.now();

      final record = TurnTimingRecord(
        turnNumber: 2,
        requestId: 'req-abc123',
        uploadMs: timings['upload_ms'],
        sttMs: timings['stt_ms'],
        llmMs: timings['llm_ms'],
        ttsMs: timings['tts_ms'],
        totalMs: timings['total_ms'],
        timestamp: timestamp,
      );

      expect(record.turnNumber, 2);
      expect(record.requestId, 'req-abc123');
      expect(record.uploadMs, 45.2);
      expect(record.sttMs, 780.5);
      expect(record.llmMs, 160.3);
      expect(record.ttsMs, 240.6);
      expect(record.totalMs, 985.0);
    });

    test('supports null timing values', () {
      final timestamp = DateTime.now();
      final record = TurnTimingRecord(
        turnNumber: 1,
        timestamp: timestamp,
      );

      expect(record.turnNumber, 1);
      expect(record.requestId, isNull);
      expect(record.uploadMs, isNull);
      expect(record.sttMs, isNull);
      expect(record.llmMs, isNull);
      expect(record.ttsMs, isNull);
      expect(record.totalMs, isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final timestamp = DateTime.now();
      final record = TurnTimingRecord(
        turnNumber: 1,
        requestId: 'req-1',
        uploadMs: 50,
        sttMs: 800,
        llmMs: 150,
        ttsMs: 200,
        totalMs: 1000,
        timestamp: timestamp,
      );

      final updated = record.copyWith(
        turnNumber: 2,
        requestId: 'req-2',
      );

      expect(updated.turnNumber, 2);
      expect(updated.requestId, 'req-2');
      expect(updated.uploadMs, 50.0); // Unchanged
      expect(updated.sttMs, 800.0); // Unchanged
      expect(updated.llmMs, 150.0); // Unchanged
      expect(updated.ttsMs, 200.0); // Unchanged
      expect(updated.totalMs, 1000.0); // Unchanged
    });

    test('equals compares all fields', () {
      final timestamp = DateTime.now();
      final record1 = TurnTimingRecord(
        turnNumber: 1,
        requestId: 'req-1',
        uploadMs: 50,
        sttMs: 800,
        llmMs: 150,
        ttsMs: 200,
        totalMs: 1000,
        timestamp: timestamp,
      );
      final record2 = TurnTimingRecord(
        turnNumber: 1,
        requestId: 'req-1',
        uploadMs: 50,
        sttMs: 800,
        llmMs: 150,
        ttsMs: 200,
        totalMs: 1000,
        timestamp: timestamp,
      );

      expect(record1, equals(record2));
    });
  });
}
