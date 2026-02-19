import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Modal bottom sheet for error recovery.
///
/// Displays error details and recovery actions (Retry/Re-record/Cancel).
/// UI adapts based on the failed stage.
class ErrorRecoverySheet extends StatelessWidget {
  const ErrorRecoverySheet({
    required this.failure,
    required this.failedStage,
    super.key,
    this.onRetry,
    this.onReRecord,
    this.onCancel,
  });

  final InterviewFailure failure;
  final InterviewStage failedStage;
  final VoidCallback? onRetry;
  final VoidCallback? onReRecord;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    // Get stage-specific icon and title
    final (stageIcon, stageTitle) = _getStageIconAndTitle();

    // Determine if re-record should be shown (hide for LLM/Thinking stage)
    final shouldShowReRecord = failedStage != InterviewStage.thinking;
    final isContentRefused =
        failure is ServerFailure &&
        (failure as ServerFailure).code == 'content_refused';
    final showPrimaryAction =
        (failure.retryable && onRetry != null) ||
        (isContentRefused && onRetry != null);
    final primaryActionLabel = isContentRefused ? 'Try Again' : 'Retry';
    final cancelLabel = isContentRefused ? 'End Session' : 'Cancel';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stage-specific error icon
            Icon(
              stageIcon,
              size: 48,
              color: VoiceMockColors.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: VoiceMockSpacing.md),

            // Stage-specific header
            Text(
              stageTitle,
              style: VoiceMockTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VoiceMockSpacing.sm),

            // Error message
            Text(
              failure.message,
              style: VoiceMockTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VoiceMockSpacing.md),

            // Request ID (copyable)
            if (failure.requestId != null) ...[
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: failure.requestId!),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request ID copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(VoiceMockSpacing.sm),
                  decoration: BoxDecoration(
                    color: VoiceMockColors.background,
                    borderRadius: BorderRadius.circular(VoiceMockRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.copy,
                        size: 16,
                        color: VoiceMockColors.textMuted,
                      ),
                      const SizedBox(width: VoiceMockSpacing.sm),
                      Flexible(
                        child: Text(
                          'ID: ${failure.requestId}',
                          style: VoiceMockTypography.small.copyWith(
                            fontFamily: 'monospace',
                            color: VoiceMockColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VoiceMockSpacing.lg),
            ],

            // Action buttons
            if (showPrimaryAction)
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: VoiceMockColors.primary,
                  foregroundColor: VoiceMockColors.surface,
                ),
                child: Text(primaryActionLabel),
              ),
            if (showPrimaryAction) const SizedBox(height: VoiceMockSpacing.sm),

            if (!isContentRefused && shouldShowReRecord && onReRecord != null)
              OutlinedButton(
                onPressed: onReRecord,
                style: OutlinedButton.styleFrom(
                  foregroundColor: VoiceMockColors.primary,
                  side: const BorderSide(color: VoiceMockColors.primary),
                ),
                child: const Text('Re-record'),
              ),
            if (!isContentRefused && shouldShowReRecord && onReRecord != null)
              const SizedBox(height: VoiceMockSpacing.sm),

            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: VoiceMockColors.textMuted,
                ),
                child: Text(cancelLabel),
              ),
          ],
        ),
      ),
    );
  }

  /// Get stage-specific icon and title.
  (IconData, String) _getStageIconAndTitle() {
    return switch (failedStage) {
      InterviewStage.uploading => (Icons.cloud_off, 'Upload failed'),
      InterviewStage.transcribing => (Icons.mic_off, 'Transcription failed'),
      InterviewStage.thinking => (Icons.psychology_alt, 'Processing failed'),
      _ => (Icons.error_outline, 'Error occurred'),
    };
  }

  /// Show the error recovery sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required InterviewFailure failure,
    required InterviewStage failedStage,
    VoidCallback? onRetry,
    VoidCallback? onReRecord,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => ErrorRecoverySheet(
        failure: failure,
        failedStage: failedStage,
        onRetry: onRetry == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onRetry();
              },
        onReRecord: onReRecord == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onReRecord();
              },
        onCancel: onCancel == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onCancel();
              },
      ),
    );
  }
}
