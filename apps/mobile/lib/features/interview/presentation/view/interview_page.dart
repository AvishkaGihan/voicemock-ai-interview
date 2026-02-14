import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/audio/audio.dart';
import 'package:voicemock/core/http/api_client.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/domain/session.dart';
import 'package:voicemock/features/interview/presentation/cubit/cubit.dart';
import 'package:voicemock/features/interview/presentation/view/interview_view.dart';

/// Interview page providing the InterviewCubit.
class InterviewPage extends StatelessWidget {
  const InterviewPage({required this.session, super.key});

  final Session session;

  static Route<void> route(Session session) {
    return MaterialPageRoute<void>(
      builder: (_) => InterviewPage(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();

    return BlocProvider(
      create: (_) => InterviewCubit(
        recordingService: RecordingService(),
        turnRemoteDataSource: TurnRemoteDataSource(apiClient),
        sessionId: session.sessionId,
        sessionToken: session.sessionToken,
        initialQuestionText: session.openingPrompt,
        totalQuestions: session.totalQuestions,
      ),
      child: const InterviewView(),
    );
  }
}
