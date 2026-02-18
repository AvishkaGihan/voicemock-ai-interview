import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/audio/audio.dart';
import 'package:voicemock/core/http/api_client.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/domain/session.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/view/interview_view.dart';

/// Interview page providing the InterviewCubit.
class InterviewPage extends StatefulWidget {
  const InterviewPage({
    required this.session,
    this.recordingServiceBuilder,
    this.playbackServiceBuilder,
    this.audioFocusServiceBuilder,
    super.key,
  });

  final Session session;
  final RecordingService Function()? recordingServiceBuilder;
  final PlaybackService Function()? playbackServiceBuilder;
  final AudioFocusService Function()? audioFocusServiceBuilder;

  static Route<void> route(Session session) {
    return MaterialPageRoute<void>(
      builder: (_) => InterviewPage(session: session),
    );
  }

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage> {
  late final RecordingService _recordingService;
  late final PlaybackService _playbackService;
  late final AudioFocusService _audioFocusService;

  @override
  void initState() {
    super.initState();
    _recordingService =
        widget.recordingServiceBuilder?.call() ?? RecordingService();
    _playbackService =
        widget.playbackServiceBuilder?.call() ?? PlaybackService();
    _audioFocusService =
        widget.audioFocusServiceBuilder?.call() ?? AudioFocusService();
    unawaited(_audioFocusService.initialize());
  }

  @override
  void dispose() {
    // Dispose services when the page is closed
    unawaited(_recordingService.dispose());
    unawaited(_playbackService.dispose());
    unawaited(_audioFocusService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();

    return BlocProvider(
      create: (_) {
        return InterviewCubit(
          recordingService: _recordingService,
          playbackService: _playbackService,
          turnRemoteDataSource: TurnRemoteDataSource(apiClient),
          sessionId: widget.session.sessionId,
          sessionToken: widget.session.sessionToken,
          audioFocusService: _audioFocusService,
          apiBaseUrl: apiClient.baseUrl,
          initialQuestionText: widget.session.openingPrompt,
          totalQuestions: widget.session.totalQuestions,
        );
      },
      child: const InterviewView(),
    );
  }
}
