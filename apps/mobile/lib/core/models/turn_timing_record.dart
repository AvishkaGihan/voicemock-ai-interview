/// Model for capturing per-turn timing metrics and metadata.
///
/// Used by diagnostics to display performance data for each turn
/// in the interview session.
library;

import 'package:equatable/equatable.dart';
import 'package:voicemock/core/models/turn_models.dart';

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
    this.ttsMs,
    this.totalMs,
  });

  /// Creates a [TurnTimingRecord] from [TurnResponseData].
  factory TurnTimingRecord.fromTurnResponseData(
    TurnResponseData data, {
    String? requestId,
  }) {
    return TurnTimingRecord(
      turnNumber: data.questionNumber,
      requestId: requestId,
      uploadMs: data.timings['upload_ms'],
      sttMs: data.timings['stt_ms'],
      llmMs: data.timings['llm_ms'],
      ttsMs: data.timings['tts_ms'],
      totalMs: data.timings['total_ms'],
      timestamp: DateTime.now(),
    );
  }

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

  /// Time taken for TTS processing (milliseconds).
  final double? ttsMs;

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
    ttsMs,
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
    double? ttsMs,
    double? totalMs,
    DateTime? timestamp,
  }) {
    return TurnTimingRecord(
      turnNumber: turnNumber ?? this.turnNumber,
      requestId: requestId ?? this.requestId,
      uploadMs: uploadMs ?? this.uploadMs,
      sttMs: sttMs ?? this.sttMs,
      llmMs: llmMs ?? this.llmMs,
      ttsMs: ttsMs ?? this.ttsMs,
      totalMs: totalMs ?? this.totalMs,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
