import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/widgets/voice_pipeline_stepper.dart';

/// Static data pipeline visualization for the Settings screen.
///
/// Shows the 5-step data flow: Your Voice → Speech Processing → Transcript
/// → AI Analysis → Feedback. Uses the same styling tokens as the interview
/// [VoicePipelineStepper] for visual consistency.
class SettingsDataPipeline extends StatelessWidget {
  const SettingsDataPipeline({super.key});

  static const _steps = [
    _PipelineStep(icon: Icons.mic_outlined, label: 'Your Voice'),
    _PipelineStep(icon: Icons.graphic_eq, label: 'Speech\nProcessing'),
    _PipelineStep(icon: Icons.description_outlined, label: 'Transcript'),
    _PipelineStep(icon: Icons.auto_awesome, label: 'AI\nAnalysis'),
    _PipelineStep(icon: Icons.chat_bubble_outline, label: 'Feedback'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VoiceMockSpacing.sm,
        vertical: VoiceMockSpacing.md,
      ),
      child: Row(
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            Expanded(child: _buildStep(_steps[i])),
            if (i < _steps.length - 1) _buildConnector(),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(_PipelineStep step) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: VoiceMockColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: VoiceMockColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(
            step.icon,
            size: 18,
            color: VoiceMockColors.primary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: VoiceMockSpacing.xs),
        Text(
          step.label,
          style: VoiceMockTypography.micro.copyWith(
            fontSize: 9,
            color: VoiceMockColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return SizedBox(
      width: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++) ...[
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: VoiceMockColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            if (i < 2) const SizedBox(width: 1),
          ],
        ],
      ),
    );
  }
}

class _PipelineStep {
  const _PipelineStep({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
