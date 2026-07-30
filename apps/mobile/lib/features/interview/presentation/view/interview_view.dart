import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/widgets/widgets.dart';

/// Main interview view displaying the interview UI.
///
/// Uses BlocBuilder to reactively update UI based on InterviewState.
/// Restructured into sectioned zones: enhanced app bar, scrollable body
/// with purpose-built section widgets, and contextual bottom action bar.
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
      backgroundColor: VoiceMockColors.background,
      appBar: _buildAppBar(context),
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
                      unawaited(context.read<InterviewCubit>().retry());
                    },
                    onReRecord: () {
                      unawaited(
                        context.read<InterviewCubit>().reRecordFromError(),
                      );
                    },
                    onCancel: () {
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
                  // ── Progress Bar ──
                  _buildProgressBar(state),

                  // ── Scrollable Body ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VoiceMockSpacing.md,
                      ),
                      child: _buildBody(context, state),
                    ),
                  ),

                  // ── Bottom Action Bar ──
                  _buildBottomBar(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Enhanced app bar with question progress.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: VoiceMockColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: VoiceMockSpacing.sm),
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: VoiceMockColors.surfaceBorder),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: VoiceMockColors.textPrimary,
              onPressed: () => _showEndSessionDialog(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: BlocBuilder<InterviewCubit, InterviewState>(
        builder: (context, state) {
          final (questionNumber, totalQuestions) =
              _getQuestionProgress(state);
          return GestureDetector(
            onTap: _onTitleTap,
            child: Column(
              children: [
                Text(
                  'INTERVIEW',
                  style: VoiceMockTypography.label.copyWith(
                    color: VoiceMockColors.textPrimary,
                    letterSpacing: 2,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (questionNumber > 0)
                  Text(
                    'Question $questionNumber of $totalQuestions',
                    style: VoiceMockTypography.micro.copyWith(
                      color: VoiceMockColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      actions: [
        // Diagnostics button (debug mode or unlocked via triple-tap)
        if (_showDiagnostics)
          IconButton(
            icon: const Icon(Icons.analytics_outlined, size: 20),
            tooltip: 'Diagnostics',
            color: VoiceMockColors.textMuted,
            onPressed: () => context.push(
              '/diagnostics',
              extra: context.read<InterviewCubit>(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: VoiceMockSpacing.sm),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: VoiceMockColors.surfaceBorder),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: VoiceMockColors.textPrimary,
              onPressed: () => _showEndSessionDialog(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  /// Progress bar below the app bar.
  Widget _buildProgressBar(InterviewState state) {
    final (questionNumber, totalQuestions) = _getQuestionProgress(state);
    if (questionNumber == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VoiceMockSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VoiceMockRadius.full),
        child: LinearProgressIndicator(
          value: questionNumber / totalQuestions,
          backgroundColor: VoiceMockColors.surfaceBorder,
          color: VoiceMockColors.primary,
          minHeight: 3,
        ),
      ),
    );
  }

  /// Builds the scrollable body content based on the current state.
  Widget _buildBody(BuildContext context, InterviewState state) {
    // For error state, show the previous state's body behind the modal
    if (state is InterviewError) {
      return _buildBody(context, state.previousState);
    }

    return switch (state) {
      InterviewIdle() => const Center(
        child: Padding(
          padding: EdgeInsets.all(VoiceMockSpacing.xxl),
          child: Text('Initializing interview...'),
        ),
      ),

      InterviewReady(
        :final questionText,
        :final previousTranscript,
        :final coachingFeedback,
        :final lastTtsAudioUrl,
      ) =>
        Column(
          children: [
            const SizedBox(height: VoiceMockSpacing.md),
            // Question Card
            TurnCard(
              questionNumber: 0, // not used anymore for display
              totalQuestions: 0,
              questionText: questionText,
              transcript: previousTranscript,
              coachingFeedback: coachingFeedback,
              isListening: true,
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
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),

      InterviewRecording(
        :final questionText,
      ) =>
        Column(
          children: [
            const SizedBox(height: VoiceMockSpacing.md),
            QuestionHeaderCard(
              questionText: questionText,
              isRecording: true,
            ),
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),

      InterviewUploading(
        :final questionText,
      ) =>
        Column(
          children: [
            const SizedBox(height: VoiceMockSpacing.md),
            QuestionHeaderCard(questionText: questionText),
            const SizedBox(height: VoiceMockSpacing.md),
            VoicePipelineStepper(currentStage: state.stage),
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),

      InterviewTranscribing(
        :final questionText,
      ) =>
        Column(
          children: [
            const SizedBox(height: VoiceMockSpacing.md),
            QuestionHeaderCard(questionText: questionText),
            const SizedBox(height: VoiceMockSpacing.md),
            VoicePipelineStepper(currentStage: state.stage),
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),

      InterviewTranscriptReview(
        :final questionNumber,
        :final totalQuestions,
        :final questionText,
        :final transcript,
        :final isLowConfidence,
      ) =>
        Column(
          children: [
            const SizedBox(height: VoiceMockSpacing.md),
            TranscriptReviewCard(
              questionNumber: questionNumber,
              totalQuestions: totalQuestions,
              questionText: questionText,
              transcript: transcript,
              isLowConfidence: isLowConfidence,
              onAccept: () =>
                  context.read<InterviewCubit>().acceptTranscript(),
              onReRecord: () => context.read<InterviewCubit>().reRecord(),
            ),
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),

      InterviewThinking(
        :final questionText,
        :final transcript,
        :final coachingFeedback,
      ) =>
        Column(
          children: [
            const SizedBox(height: VoiceMockSpacing.md),
            TurnCard(
              questionNumber: 0,
              totalQuestions: 0,
              questionText: questionText,
              transcript: transcript,
              coachingFeedback: coachingFeedback,
            ),
            const SizedBox(height: VoiceMockSpacing.md),
            VoicePipelineStepper(currentStage: state.stage),
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),

      InterviewSpeaking(
        :final questionText,
        :final transcript,
        :final responseText,
        :final coachingFeedback,
        :final isPaused,
      ) =>
        Column(
          children: [
            const SizedBox(height: VoiceMockSpacing.md),
            TurnCard(
              questionNumber: 0,
              totalQuestions: 0,
              questionText: questionText,
              transcript: transcript,
              responseText: responseText,
              coachingFeedback: coachingFeedback,
            ),
            const SizedBox(height: VoiceMockSpacing.md),
            PlaybackControlBar(
              isPaused: isPaused,
              isBuffering: state.isBuffering,
              onPause: () =>
                  context.read<InterviewCubit>().pausePlayback(),
              onResume: () =>
                  context.read<InterviewCubit>().resumePlayback(),
              onStop: () =>
                  context.read<InterviewCubit>().stopPlayback(),
            ),
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),

      InterviewSessionComplete(
        :final totalQuestions,
        :final lastTranscript,
        :final lastResponseText,
        :final sessionSummary,
      ) =>
        Column(
          children: [
            const SizedBox(height: VoiceMockSpacing.md),
            SessionCompleteCard(
              totalQuestions: totalQuestions,
              lastTranscript: lastTranscript,
              lastResponseText: lastResponseText,
              sessionSummary: sessionSummary,
              onBackToHome: () => Navigator.pop(context),
              onStartNew: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: VoiceMockSpacing.md),
          ],
        ),

      // InterviewError is handled by BlocListener showing modal bottom sheet
      InterviewError() => const SizedBox.shrink(),
    };
  }

  /// Bottom action bar — contextual actions anchored at screen bottom.
  Widget _buildBottomBar(BuildContext context, InterviewState state) {
    final cubit = context.read<InterviewCubit>();

    // Hide bottom bar for states that have their own actions or don't need them
    if (state is InterviewSessionComplete ||
        state is InterviewTranscriptReview ||
        state is InterviewSpeaking ||
        state is InterviewIdle) {
      return const SizedBox.shrink();
    }

    // For error state, show based on previous state
    if (state is InterviewError) {
      return const SizedBox.shrink();
    }

    final isRecording = state is InterviewRecording;
    final isReady = state is InterviewReady;

    // Only show recording zone for ready/recording states
    if (!isReady && !isRecording) {
      return const SizedBox.shrink();
    }

    // Recording zone as bottom action
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VoiceMockSpacing.md,
        VoiceMockSpacing.sm,
        VoiceMockSpacing.md,
        VoiceMockSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VoiceMockColors.background.withValues(alpha: 0),
            VoiceMockColors.background.withValues(alpha: 0.9),
            VoiceMockColors.background,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: state is InterviewRecording
          ? _RecordingTimer(
              startTime: state.recordingStartTime,
              builder: (context, duration) {
                return RecordingZone(
                  isEnabled: true,
                  isRecording: true,
                  recordingDuration: duration,
                  onPressStart: cubit.startRecording,
                  onPressEnd: cubit.stopRecording,
                );
              },
            )
          : RecordingZone(
              isEnabled: isReady,
              isRecording: false,
              onPressStart: cubit.startRecording,
              onPressEnd: cubit.stopRecording,
            ),
    );
  }

  /// Extract question number and total from any state.
  (int, int) _getQuestionProgress(InterviewState state) {
    return switch (state) {
      InterviewIdle() => (0, 0),
      InterviewReady(
        :final questionNumber,
        :final totalQuestions,
      ) =>
        (questionNumber, totalQuestions),
      InterviewRecording(
        :final questionNumber,
        :final totalQuestions,
      ) =>
        (questionNumber, totalQuestions),
      InterviewUploading(
        :final questionNumber,
        :final totalQuestions,
      ) =>
        (questionNumber, totalQuestions),
      InterviewTranscribing(
        :final questionNumber,
        :final totalQuestions,
      ) =>
        (questionNumber, totalQuestions),
      InterviewTranscriptReview(
        :final questionNumber,
        :final totalQuestions,
      ) =>
        (questionNumber, totalQuestions),
      InterviewThinking(
        :final questionNumber,
        :final totalQuestions,
      ) =>
        (questionNumber, totalQuestions),
      InterviewSpeaking(
        :final questionNumber,
        :final totalQuestions,
      ) =>
        (questionNumber, totalQuestions),
      InterviewSessionComplete(:final totalQuestions) =>
        (totalQuestions, totalQuestions),
      InterviewError(:final previousState) =>
        _getQuestionProgress(previousState),
    };
  }

  Future<void> _showEndSessionDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VoiceMockColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VoiceMockRadius.lg),
        ),
        title: Text('End session?', style: VoiceMockTypography.h3),
        content: Text(
          'Are you sure you want to end this interview session?',
          style: VoiceMockTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: VoiceMockColors.textMuted,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: VoiceMockColors.error,
            ),
            child: const Text('End'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      final cubit = context.read<InterviewCubit>();
      Navigator.pop(context);
      unawaited(cubit.cancel());
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
