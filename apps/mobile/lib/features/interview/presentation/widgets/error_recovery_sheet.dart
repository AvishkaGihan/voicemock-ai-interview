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
        padding: const EdgeInsets.all(VoiceMockSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stage-specific error icon
            Container(
              padding: const EdgeInsets.all(VoiceMockSpacing.md),
              decoration: BoxDecoration(
                color: VoiceMockColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: VoiceMockColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                stageIcon,
                size: 40,
                color: VoiceMockColors.error.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: VoiceMockSpacing.md),

            // Stage-specific header
            Text(
              '✦ $stageTitle',
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
                  decoration: VoiceMockColors.cardDecoration(
                    radius: VoiceMockRadius.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.copy,
                        size: 14,
                        color: VoiceMockColors.textMuted,
                      ),
                      const SizedBox(width: VoiceMockSpacing.sm),
                      Flexible(
                        child: Text(
                          'ID: ${failure.requestId}',
                          style: VoiceMockTypography.small.copyWith(
                            fontFamily: 'monospace',
                            color: VoiceMockColors.textMuted,
                            fontSize: 12,
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
            if (showPrimaryAction) ...[
              // Gradient CTA for retry
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(VoiceMockRadius.full),
                  gradient: const LinearGradient(
                    colors: [
                      VoiceMockColors.gradientStart,
                      VoiceMockColors.gradientEnd,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VoiceMockColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onRetry,
                    borderRadius: BorderRadius.circular(VoiceMockRadius.full),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Text(
                        primaryActionLabel,
                        style: VoiceMockTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: VoiceMockColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VoiceMockSpacing.sm),
            ],

            if (!isContentRefused && shouldShowReRecord && onReRecord != null)
              ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onReRecord,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VoiceMockColors.primary,
                      side: const BorderSide(color: VoiceMockColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(VoiceMockRadius.full),
                      ),
                    ),
                    child: const Text('Re-record'),
                  ),
                ),
                const SizedBox(height: VoiceMockSpacing.sm),
              ],

            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: VoiceMockColors.textMuted,
                  textStyle: VoiceMockTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
      backgroundColor: VoiceMockColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VoiceMockRadius.xl),
        ),
      ),
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
