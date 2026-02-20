/// Widget displaying timing metrics for a single turn.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemock/core/models/turn_timing_record.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

/// Displays a single turn's timing breakdown with copyable request ID.
///
/// Shows:
/// - Turn number
/// - Request ID (tap to copy)
/// - Stage timings: upload, STT, LLM, total (in milliseconds)
class TimingRow extends StatelessWidget {
  const TimingRow({required this.record, super.key});

  final TurnTimingRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: VoiceMockColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VoiceMockRadius.md),
        side: BorderSide(
          color: VoiceMockColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VoiceMockSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Turn number
            Row(
              children: [
                Text(
                  'Turn ${record.turnNumber}',
                  style: VoiceMockTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (record.totalMs != null)
                  Text(
                    '${record.totalMs!.toStringAsFixed(0)}ms total',
                    style: VoiceMockTypography.small.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: VoiceMockSpacing.sm),

            // Request ID (tap to copy)
            if (record.requestId != null)
              GestureDetector(
                onTap: () => _copyRequestId(context),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tag,
                      size: 14,
                      color: VoiceMockColors.textMuted, // 0xFF94A3B8 -> approx
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        record.requestId!,
                        style: VoiceMockTypography.small.copyWith(
                          fontFamily: 'monospace',
                          color: VoiceMockColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.content_copy,
                      size: 14,
                      color: VoiceMockColors.textMuted,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Stage timings
            Wrap(
              spacing: VoiceMockSpacing.md,
              runSpacing: VoiceMockSpacing.sm,
              children: [
                if (record.uploadMs != null)
                  _TimingChip(
                    label: 'Upload',
                    value: record.uploadMs!,
                  ),
                if (record.sttMs != null)
                  _TimingChip(
                    label: 'STT',
                    value: record.sttMs!,
                  ),
                if (record.llmMs != null)
                  _TimingChip(
                    label: 'LLM',
                    value: record.llmMs!,
                  ),
                if (record.ttsMs != null)
                  _TimingChip(
                    label: 'TTS',
                    value: record.ttsMs!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyRequestId(BuildContext context) {
    if (record.requestId != null) {
      unawaited(Clipboard.setData(ClipboardData(text: record.requestId!)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request ID copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Compact chip displaying a single timing metric.
class _TimingChip extends StatelessWidget {
  const _TimingChip({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: VoiceMockColors.surface,
        borderRadius: BorderRadius.circular(VoiceMockRadius.sm),
        border: Border.all(
          color: VoiceMockColors.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}ms',
        style: VoiceMockTypography.small.copyWith(
          fontWeight: FontWeight.w500,
          color: VoiceMockColors.textMuted,
        ),
      ),
    );
  }
}
