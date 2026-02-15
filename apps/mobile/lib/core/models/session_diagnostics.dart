/// Session-level diagnostics data accumulator.
///
/// Collects per-turn timing records and error metadata
/// for display in the diagnostics screen.
library;

import 'package:equatable/equatable.dart';
import 'package:voicemock/core/models/turn_timing_record.dart';

/// Accumulator for diagnostic data across an interview session.
///
/// Maintains a list of per-turn timing records and tracks
/// the last error's  request ID and stage for troubleshooting.
class SessionDiagnostics extends Equatable {
  /// Creates session diagnostics.
  const SessionDiagnostics({
    required this.sessionId,
    this.turnRecords = const [],
    this.lastErrorRequestId,
    this.lastErrorStage,
  });

  /// Session ID for correlation with backend logs.
  final String sessionId;

  /// List of timing records for each turn in the session.
  final List<TurnTimingRecord> turnRecords;

  /// Request ID of the last error (if any).
  final String? lastErrorRequestId;

  /// Stage where the last error occurred (e.g., "stt", "llm").
  final String? lastErrorStage;

  @override
  List<Object?> get props => [
    sessionId,
    turnRecords,
    lastErrorRequestId,
    lastErrorStage,
  ];

  /// Adds a turn timing record to the diagnostics.
  SessionDiagnostics addTurn(TurnTimingRecord record) {
    return SessionDiagnostics(
      sessionId: sessionId,
      turnRecords: [...turnRecords, record],
      lastErrorRequestId: lastErrorRequestId,
      lastErrorStage: lastErrorStage,
    );
  }

  /// Records error metadata for the last failed turn.
  SessionDiagnostics recordError(String requestId, String stage) {
    return SessionDiagnostics(
      sessionId: sessionId,
      turnRecords: turnRecords,
      lastErrorRequestId: requestId,
      lastErrorStage: stage,
    );
  }

  /// Creates a copy with the given fields replaced.
  SessionDiagnostics copyWith({
    String? sessionId,
    List<TurnTimingRecord>? turnRecords,
    String? lastErrorRequestId,
    String? lastErrorStage,
  }) {
    return SessionDiagnostics(
      sessionId: sessionId ?? this.sessionId,
      turnRecords: turnRecords ?? this.turnRecords,
      lastErrorRequestId: lastErrorRequestId ?? this.lastErrorRequestId,
      lastErrorStage: lastErrorStage ?? this.lastErrorStage,
    );
  }
}
