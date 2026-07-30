import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Visual pipeline stepper showing processing stages.
///
/// Displays steps (Upload → Transcribe → Review → Thinking → Speaking)
/// with animated indicators and connecting lines.
class VoicePipelineStepper extends StatefulWidget {
  const VoicePipelineStepper({
    required this.currentStage,
    super.key,
  });

  final InterviewStage currentStage;

  @override
  State<VoicePipelineStepper> createState() => _VoicePipelineStepperState();
}

class _VoicePipelineStepperState extends State<VoicePipelineStepper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide stepper if not in a pipeline stage
    if (widget.currentStage == InterviewStage.ready ||
        widget.currentStage == InterviewStage.recording ||
        widget.currentStage == InterviewStage.sessionComplete ||
        widget.currentStage == InterviewStage.error) {
      return const SizedBox.shrink();
    }

    final steps = [
      _StepConfig(
        stage: InterviewStage.uploading,
        label: 'Upload',
        icon: Icons.cloud_upload_outlined,
      ),
      _StepConfig(
        stage: InterviewStage.transcribing,
        label: 'Transcribe',
        icon: Icons.graphic_eq,
      ),
      _StepConfig(
        stage: InterviewStage.transcriptReview,
        label: 'Review',
        icon: Icons.rate_review_outlined,
      ),
      _StepConfig(
        stage: InterviewStage.thinking,
        label: 'Thinking',
        icon: Icons.psychology_outlined,
      ),
      _StepConfig(
        stage: InterviewStage.speaking,
        label: 'Speaking',
        icon: Icons.record_voice_over_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: VoiceMockSpacing.sm,
        horizontal: VoiceMockSpacing.sm,
      ),
      decoration: VoiceMockColors.cardDecoration(
        radius: VoiceMockRadius.md,
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _buildStep(context, steps[i]),
            ),
            if (i < steps.length - 1)
              _buildConnector(context, steps[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, _StepConfig config) {
    final isActive = widget.currentStage == config.stage;
    final isCompleted = widget.currentStage.index > config.stage.index;

    // Determine icon color based on state
    Color iconColor;
    if (isActive) {
      iconColor = VoiceMockColors.primary;
    } else if (isCompleted) {
      iconColor = VoiceMockColors.primary;
    } else {
      iconColor = VoiceMockColors.textMuted.withValues(alpha: 0.3);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: isActive ? _fadeAnimation.value : 1.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(VoiceMockRadius.full),
                  color: isActive
                      ? VoiceMockColors.primary.withValues(alpha: 0.12)
                      : (isCompleted
                          ? VoiceMockColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent),
                  border: Border.all(
                    color: isActive || isCompleted
                        ? VoiceMockColors.primary.withValues(alpha: 0.3)
                        : VoiceMockColors.surfaceBorder,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : config.icon,
                  color: iconColor,
                  size: 16,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          config.label,
          style: VoiceMockTypography.micro.copyWith(
            color: isActive
                ? VoiceMockColors.primary
                : (isCompleted
                      ? VoiceMockColors.textPrimary
                      : VoiceMockColors.textMuted),
            fontWeight: isActive || isCompleted
                ? FontWeight.w600
                : FontWeight.w400,
            fontSize: 9,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildConnector(
    BuildContext context,
    _StepConfig current,
  ) {
    final isCompleted = widget.currentStage.index > current.stage.index;
    final isActive = widget.currentStage == current.stage;

    return SizedBox(
      width: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: isCompleted
                  ? const LinearGradient(
                      colors: [
                        VoiceMockColors.primary,
                        VoiceMockColors.primary,
                      ],
                    )
                  : (isActive
                        ? LinearGradient(
                            colors: [
                              VoiceMockColors.primary,
                              VoiceMockColors.primary.withValues(
                                alpha: _fadeAnimation.value * 0.3,
                              ),
                            ],
                          )
                        : const LinearGradient(
                            colors: [
                              VoiceMockColors.surfaceBorder,
                              VoiceMockColors.surfaceBorder,
                            ],
                          )),
            ),
          );
        },
      ),
    );
  }
}

class _StepConfig {
  _StepConfig({
    required this.stage,
    required this.label,
    required this.icon,
  });

  final InterviewStage stage;
  final String label;
  final IconData icon;
}
