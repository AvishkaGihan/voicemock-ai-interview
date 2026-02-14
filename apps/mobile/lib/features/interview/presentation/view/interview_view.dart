import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
      InterviewTranscriptReview(
        :final questionNumber,
        :final questionText,
        :final transcript,
        :final isLowConfidence,
      ) =>
        TranscriptReviewCard(
          questionNumber: questionNumber,
          totalQuestions: 5,
          questionText: questionText,
          transcript: transcript,
          isLowConfidence: isLowConfidence,
          onAccept: () => context.read<InterviewCubit>().acceptTranscript(),
          onReRecord: () => context.read<InterviewCubit>().reRecord(),
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
      InterviewSessionComplete(
        :final totalQuestions,
        :final lastTranscript,
        :final lastResponseText,
      ) =>
        SessionCompleteCard(
          totalQuestions: totalQuestions,
          lastTranscript: lastTranscript,
          lastResponseText: lastResponseText,
          onBackToHome: () => Navigator.pop(context),
          onStartNew: () {
            // Navigate to home then to setup (or directly to setup)
            Navigator.pop(context);
          },
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

    // Hide button during session complete
    if (state is InterviewSessionComplete) {
      return const SizedBox.shrink();
    }

    if (state is InterviewRecording) {
      return _RecordingTimer(
        startTime: state.recordingStartTime,
        builder: (context, duration) {
          return HoldToTalkButton(
            isEnabled: isEnabled,
            isRecording: true,
            recordingDuration: duration,
            onPressStart: cubit.startRecording,
            onPressEnd: cubit.stopRecording,
          );
        },
      );
    }

    return HoldToTalkButton(
      isEnabled: isEnabled,
      isRecording: false,
      onPressStart: cubit.startRecording,
      onPressEnd: cubit.stopRecording,
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
      await context.read<InterviewCubit>().cancel();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _RecordingTimer extends StatefulWidget {
  const _RecordingTimer({required this.startTime, required this.builder});

  final DateTime startTime;
  final Widget Function(BuildContext, Duration) builder;

  @override
  State<_RecordingTimer> createState() => _RecordingTimerState();
}

class _RecordingTimerState extends State<_RecordingTimer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final newDuration = DateTime.now().difference(widget.startTime);
      if (newDuration.inSeconds != _duration.inSeconds) {
        setState(() {
          _duration = newDuration;
        });
      }
    });
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _duration);
  }
}
