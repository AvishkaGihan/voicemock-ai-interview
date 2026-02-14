import 'package:flutter/material.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// 5-step horizontal stepper showing voice pipeline progress.
///
/// Displays stages: Uploading → Transcribing → Review → Thinking → Speaking
/// with visual indicators for pending/active/complete/error states.
class VoicePipelineStepper extends StatelessWidget {
  const VoicePipelineStepper({
    required this.currentStage,
    super.key,
    this.hasError = false,
    this.errorStage,
    this.stageStartTime,
  });

  final InterviewStage currentStage;
  final bool hasError;
  final InterviewStage? errorStage;
  final DateTime? stageStartTime;

  @override
  Widget build(BuildContext context) {
    // Hide stepper during Ready/Recording states
    if (currentStage == InterviewStage.ready ||
        currentStage == InterviewStage.recording) {
      return const SizedBox.shrink();
    }

    // Hide stepper during session complete
    if (currentStage == InterviewStage.sessionComplete) {
      return const SizedBox.shrink();
    }

    final showHint = _shouldShowHint();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStep(
                context,
                label: 'Uploading',
                icon: Icons.upload,
                stage: InterviewStage.uploading,
              ),
              _buildConnector(context),
              _buildStep(
                context,
                label: 'Transcribing',
                icon: Icons.transcribe,
                stage: InterviewStage.transcribing,
              ),
              _buildConnector(context),
              _buildStep(
                context,
                label: 'Review',
                icon: Icons.rate_review,
                stage: InterviewStage.transcriptReview,
              ),
              _buildConnector(context),
              _buildStep(
                context,
                label: 'Thinking',
                icon: Icons.lightbulb_outline,
                stage: InterviewStage.thinking,
              ),
              _buildConnector(context),
              _buildStep(
                context,
                label: 'Speaking',
                icon: Icons.volume_up,
                stage: InterviewStage.speaking,
              ),
            ],
          ),
        ),
        if (showHint)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Usually ~5-15s',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String label,
    required IconData icon,
    required InterviewStage stage,
  }) {
    final stepState = _getStepState(stage);
    final color = _getStepColor(context, stepState);
    final stepIcon = _getStepIcon(icon, stepState);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          stepIcon,
          size: 24,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: stepState == _StepState.active
                ? FontWeight.w600
                : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  _StepState _getStepState(InterviewStage stage) {
    if (hasError && stage == errorStage) {
      return _StepState.error;
    }

    final stageOrder = [
      InterviewStage.uploading,
      InterviewStage.transcribing,
      InterviewStage.transcriptReview,
      InterviewStage.thinking,
      InterviewStage.speaking,
    ];

    final currentIndex = stageOrder.indexOf(currentStage);
    final stepIndex = stageOrder.indexOf(stage);

    if (stepIndex < currentIndex) {
      return _StepState.complete;
    } else if (stepIndex == currentIndex) {
      return _StepState.active;
    } else {
      return _StepState.pending;
    }
  }

  Color _getStepColor(BuildContext context, _StepState state) {
    switch (state) {
      case _StepState.complete:
        return Theme.of(context).colorScheme.primary;
      case _StepState.active:
        return Theme.of(context).colorScheme.primary;
      case _StepState.error:
        return Theme.of(context).colorScheme.error;
      case _StepState.pending:
        return Theme.of(context).colorScheme.outline;
    }
  }

  IconData _getStepIcon(IconData defaultIcon, _StepState state) {
    if (state == _StepState.complete) {
      return Icons.check_circle;
    } else if (state == _StepState.error) {
      return Icons.error_outline;
    }
    return defaultIcon;
  }

  bool _shouldShowHint() {
    if (stageStartTime == null) return false;
    if (!currentStage.isProcessing) return false;

    final elapsed = DateTime.now().difference(stageStartTime!);
    return elapsed.inSeconds > 10;
  }
}

enum _StepState {
  pending,
  active,
  complete,
  error,
}
