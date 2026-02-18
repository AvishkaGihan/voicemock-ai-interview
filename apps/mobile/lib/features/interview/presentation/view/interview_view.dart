import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/widgets/widgets.dart';

/// Main interview view displaying the interview UI.
///
/// Uses BlocBuilder to reactively update UI based on InterviewState.
class InterviewView extends StatefulWidget {
  const InterviewView({super.key});

  @override
  State<InterviewView> createState() => _InterviewViewState();
}

class _InterviewViewState extends State<InterviewView>
    with WidgetsBindingObserver {
  static const _interruptionMessage =
      'Recording interrupted — hold to try again';
  int _debugTapCount = 0;
  bool _showDiagnostics = kDebugMode; // Always show in debug mode

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle backgrounding: if recording, cancel the recording
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final interviewCubit = context.read<InterviewCubit>();
      final currentState = interviewCubit.state;

      if (currentState is InterviewRecording) {
        unawaited(interviewCubit.cancelRecording(wasInterrupted: true));
      }
    }
  }

  void _onTitleTap() {
    setState(() {
      _debugTapCount++;
      if (_debugTapCount >= 3) {
        _showDiagnostics = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagnostics mode enabled'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _onTitleTap,
          child: const Text('Interview'),
        ),
        actions: [
          // Diagnostics button (debug mode or unlocked via triple-tap)
          if (_showDiagnostics)
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: 'Diagnostics',
              onPressed: () => context.push(
                '/diagnostics',
                extra: context.read<InterviewCubit>(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showEndSessionDialog(context),
          ),
        ],
      ),
      body: BlocListener<InterviewCubit, InterviewState>(
        listener: (context, state) {
          // Show interruption feedback when recording was interrupted
          if (state is InterviewReady && state.wasInterrupted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(_interruptionMessage),
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }

          // Show error recovery sheet as modal bottom sheet
          if (state is InterviewError) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                unawaited(
                  ErrorRecoverySheet.show(
                    context,
                    failure: state.failure,
                    failedStage: state.failedStage,
                    onRetry: () {
                      Navigator.pop(context); // Close sheet
                      unawaited(context.read<InterviewCubit>().retry());
                    },
                    onReRecord: () {
                      Navigator.pop(context); // Close sheet
                      unawaited(
                        context.read<InterviewCubit>().reRecordFromError(),
                      );
                    },
                    onCancel: () {
                      Navigator.pop(context); // Close sheet
                      unawaited(context.read<InterviewCubit>().cancel());
                    },
                  ),
                );
              }
            });
          }
        },
        child: BlocBuilder<InterviewCubit, InterviewState>(
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
      ),
    );
  }

  Widget _buildTurnCard(BuildContext context, InterviewState state) {
    // For error state, show the previous state's turn card behind the modal
    if (state is InterviewError) {
      return _buildTurnCard(context, state.previousState);
    }

    return switch (state) {
      InterviewIdle() => const Center(
        child: Text('Initializing interview...'),
      ),
      InterviewReady(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
        :final previousTranscript,
        :final lastTtsAudioUrl,
      ) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: totalQuestions,
          questionText: questionText,
          transcript: previousTranscript,
          onReplay: lastTtsAudioUrl.isNotEmpty
              ? () async {
                  final replayStarted = await context
                      .read<InterviewCubit>()
                      .replayLastResponse();
                  if (!replayStarted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Response audio expired'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              : null,
        ),
      InterviewRecording(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
      ) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: totalQuestions,
          questionText: questionText,
        ),
      InterviewUploading(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
      ) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: totalQuestions,
          questionText: questionText,
        ),
      InterviewTranscribing(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
      ) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: totalQuestions,
          questionText: questionText,
        ),
      InterviewTranscriptReview(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
        :final transcript,
        :final isLowConfidence,
      ) =>
        TranscriptReviewCard(
          questionNumber: questionNumber,
          totalQuestions: totalQuestions,
          questionText: questionText,
          transcript: transcript,
          isLowConfidence: isLowConfidence,
          onAccept: () => context.read<InterviewCubit>().acceptTranscript(),
          onReRecord: () => context.read<InterviewCubit>().reRecord(),
        ),
      InterviewThinking(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
        :final transcript,
      ) =>
        TurnCard(
          questionNumber: questionNumber,
          totalQuestions: totalQuestions,
          questionText: questionText,
          transcript: transcript,
        ),
      InterviewSpeaking(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
        :final transcript,
        :final responseText,
        :final isPaused,
      ) =>
        Column(
          children: [
            TurnCard(
              questionNumber: questionNumber,
              totalQuestions: totalQuestions,
              questionText: questionText,
              transcript: transcript,
              responseText: responseText,
            ),
            PlaybackControlBar(
              isPaused: isPaused,
              isBuffering: state.isBuffering,
              onPause: () => context.read<InterviewCubit>().pausePlayback(),
              onResume: () => context.read<InterviewCubit>().resumePlayback(),
              onStop: () => context.read<InterviewCubit>().stopPlayback(),
            ),
          ],
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
      // InterviewError is handled by BlocListener showing modal bottom sheet
      InterviewError() => const SizedBox.shrink(),
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
