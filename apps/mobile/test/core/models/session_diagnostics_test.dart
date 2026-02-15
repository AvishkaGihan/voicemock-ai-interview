/// Unit tests for SessionDiagnostics model.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/models/session_diagnostics.dart';
import 'package:voicemock/core/models/turn_timing_record.dart';

void main() {
  group('SessionDiagnostics', () {
    test('creates instance with session ID', () {
      const diagnostics = SessionDiagnostics(sessionId: 'session-123');

      expect(diagnostics.sessionId, 'session-123');
      expect(diagnostics.turnRecords, isEmpty);
      expect(diagnostics.lastErrorRequestId, isNull);
      expect(diagnostics.lastErrorStage, isNull);
    });

    test('addTurn accumulates records correctly', () {
      const diagnostics = SessionDiagnostics(sessionId: 'session-123');
      final timestamp = DateTime.now();

      final record1 = TurnTimingRecord(
        turnNumber: 1,
        requestId: 'req-1',
        uploadMs: 50,
        sttMs: 800,
        llmMs: 150,
        totalMs: 1000,
        timestamp: timestamp,
      );

      final record2 = TurnTimingRecord(
        turnNumber: 2,
        requestId: 'req-2',
        uploadMs: 45,
        sttMs: 780,
        llmMs: 160,
        totalMs: 985,
        timestamp: timestamp,
      );

      final updated1 = diagnostics.addTurn(record1);
      expect(updated1.turnRecords.length, 1);
      expect(updated1.turnRecords.first, record1);

      final updated2 = updated1.addTurn(record2);
      expect(updated2.turnRecords.length, 2);
      expect(updated2.turnRecords[0], record1);
      expect(updated2.turnRecords[1], record2);

      // Verify immutability - original unchanged
      expect(diagnostics.turnRecords, isEmpty);
    });

    test('recordError captures last error', () {
      const diagnostics = SessionDiagnostics(sessionId: 'session-123');

      final withError = diagnostics.recordError('req-err-1', 'stt');

      expect(withError.lastErrorRequestId, 'req-err-1');
      expect(withError.lastErrorStage, 'stt');

      // Verify immutability - original unchanged
      expect(diagnostics.lastErrorRequestId, isNull);
      expect(diagnostics.lastErrorStage, isNull);
    });

    test('recordError overwrites previous error', () {
      const diagnostics = SessionDiagnostics(sessionId: 'session-123');

      final withError1 = diagnostics.recordError('req-err-1', 'stt');
      final withError2 = withError1.recordError('req-err-2', 'llm');

      expect(withError2.lastErrorRequestId, 'req-err-2');
      expect(withError2.lastErrorStage, 'llm');
    });

    test('recordError preserves turn records', () {
      const diagnostics = SessionDiagnostics(sessionId: 'session-123');
      final timestamp = DateTime.now();

      final record = TurnTimingRecord(
        turnNumber: 1,
        requestId: 'req-1',
        uploadMs: 50,
        sttMs: 800,
        llmMs: 150,
        totalMs: 1000,
        timestamp: timestamp,
      );

      final withTurn = diagnostics.addTurn(record);
      final withError = withTurn.recordError('req-err', 'llm');

      expect(withError.turnRecords.length, 1);
      expect(withError.turnRecords.first, record);
      expect(withError.lastErrorRequestId, 'req-err');
      expect(withError.lastErrorStage, 'llm');
    });

    test('equals compares all fields', () {
      const diagnostics1 = SessionDiagnostics(sessionId: 'session-123');
      const diagnostics2 = SessionDiagnostics(sessionId: 'session-123');

      expect(diagnostics1, equals(diagnostics2));
    });

    test('copyWith creates new instance with updated fields', () {
      const diagnostics = SessionDiagnostics(
        sessionId: 'session-123',
        lastErrorRequestId: 'req-1',
        lastErrorStage: 'stt',
      );

      final updated = diagnostics.copyWith(
        lastErrorRequestId: 'req-2',
        lastErrorStage: 'llm',
      );

      expect(updated.sessionId, 'session-123'); // Unchanged
      expect(updated.lastErrorRequestId, 'req-2');
      expect(updated.lastErrorStage, 'llm');
    });
  });
}
