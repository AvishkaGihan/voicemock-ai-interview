import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/widgets/widgets.dart';

/// Main interview view displaying the interview UI.
///
/// Uses BlocBuilder to reactively update UI based on InterviewState.
class InterviewView extends StatelessWidget {
  const InterviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showEndSessionDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<InterviewCubit, InterviewState>(
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                // Voice Pipeline Stepper (shown during processing)
                VoicePipelineStepper(
                  currentStage: state.stage,
                  stageStartTime: _getStageStartTime(state),
                ),

                // Turn Card (question, transcript, response)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTurnCard(context, state),
                  ),
                ),

                // Hold-to-Talk Button (anchored at bottom)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildHoldToTalkButton(context, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTurnCard(BuildContext context, InterviewState state) {
    return switch (state) {
      InterviewIdle() => const Center(
        child: Text('Initializing interview...'),
      ),
      InterviewReady(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
        :final previousTranscript,
      ) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: totalQuestions,
          questionText: questionText,
          transcript: previousTranscript,
        ),
      InterviewRecording(:final questionNumber, :final questionText) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: 5,
          questionText: questionText,
        ),
      InterviewUploading(:final questionNumber, :final questionText) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: 5,
          questionText: questionText,
        ),
      InterviewTranscribing(:final questionNumber, :final questionText) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: 5,
          questionText: questionText,
        ),
      InterviewThinking(
        :final questionNumber,
        :final questionText,
        :final transcript,
      ) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: 5,
          questionText: questionText,
          transcript: transcript,
        ),
      InterviewSpeaking(
        :final questionNumber,
        :final questionText,
        :final transcript,
        :final responseText,
      ) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: 5,
          questionText: questionText,
          transcript: transcript,
          responseText: responseText,
        ),
      InterviewError(:final failure) => ErrorRecoverySheet(
        failure: failure,
        onRetry: () => context.read<InterviewCubit>().retry(),
        onCancel: () => context.read<InterviewCubit>().cancel(),
      ),
    };
  }

  Widget _buildHoldToTalkButton(BuildContext context, InterviewState state) {
    final cubit = context.read<InterviewCubit>();
    final isEnabled = state is InterviewReady || state is InterviewRecording;
    final isRecording = state is InterviewRecording;
    final recordingDuration = state is InterviewRecording
        ? DateTime.now().difference(state.recordingStartTime)
        : null;

    return HoldToTalkButton(
      isEnabled: isEnabled,
      isRecording: isRecording,
      recordingDuration: recordingDuration,
      onPressStart: cubit.startRecording,
      onPressEnd: () => cubit.stopRecording('/mock/path/audio.m4a'),
    );
  }

  DateTime? _getStageStartTime(InterviewState state) {
    return switch (state) {
      InterviewUploading(:final startTime) => startTime,
      InterviewTranscribing(:final startTime) => startTime,
      InterviewThinking(:final startTime) => startTime,
      _ => null,
    };
  }

  Future<void> _showEndSessionDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End session?'),
        content: const Text(
          'Are you sure you want to end this interview session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<InterviewCubit>().cancel();
      Navigator.pop(context);
    }
  }
}
