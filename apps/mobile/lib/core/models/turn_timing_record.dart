/// Model for capturing per-turn timing metrics and metadata.
///
/// Used by diagnostics to display performance data for each turn
/// in the interview session.
library;

import 'package:equatable/equatable.dart';

/// Record of timing metrics for a single turn.
///
/// Captures stage-wise timing data (upload, STT, LLM, total)
/// along with turn number and request ID for troubleshooting.
class TurnTimingRecord extends Equatable {
  /// Creates a turn timing record.
  const TurnTimingRecord({
    required this.turnNumber,
    required this.timestamp,
    this.requestId,
    this.uploadMs,
    this.sttMs,
    this.llmMs,
    this.totalMs,
  });

  /// Turn number in the session (1-indexed).
  final int turnNumber;

  /// Request ID from the backend response (for correlation).
  final String? requestId;

  /// Time taken for audio upload (milliseconds).
  final double? uploadMs;

  /// Time taken for speech-to-text processing (milliseconds).
  final double? sttMs;

  /// Time taken for LLM processing (milliseconds).
  final double? llmMs;

  /// Total processing time (milliseconds).
  final double? totalMs;

  /// Timestamp when this turn was recorded.
  final DateTime timestamp;

  @override
  List<Object?> get props => [
    turnNumber,
    requestId,
    uploadMs,
    sttMs,
    llmMs,
    totalMs,
    timestamp,
  ];

  /// Creates a copy with the given fields replaced.
  TurnTimingRecord copyWith({
    int? turnNumber,
    String? requestId,
    double? uploadMs,
    double? sttMs,
    double? llmMs,
    double? totalMs,
    DateTime? timestamp,
  }) {
    return TurnTimingRecord(
      turnNumber: turnNumber ?? this.turnNumber,
      requestId: requestId ?? this.requestId,
      uploadMs: uploadMs ?? this.uploadMs,
      sttMs: sttMs ?? this.sttMs,
      llmMs: llmMs ?? this.llmMs,
      totalMs: totalMs ?? this.totalMs,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
