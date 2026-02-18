import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              color: Theme.of(context).colorScheme.error.withAlpha(204),
            ),
            const SizedBox(height: 16),

            // Stage-specific header
            Text(
              stageTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Error message
            Text(
              failure.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'ID: ${failure.requestId}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            if (failure.retryable && onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            if (failure.retryable && onRetry != null)
              const SizedBox(height: 12),

            if (shouldShowReRecord && onReRecord != null)
              TextButton(
                onPressed: onReRecord,
                child: const Text('Re-record'),
              ),
            if (shouldShowReRecord && onReRecord != null)
              const SizedBox(height: 8),

            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
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
