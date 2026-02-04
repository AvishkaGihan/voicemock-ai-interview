import 'package:flutter/material.dart';

import 'package:voicemock/features/interview/domain/session.dart';
import 'package:voicemock/features/interview/presentation/view/interview_view.dart';

/// Page wrapper for interview screen with session.
class InterviewPage extends StatelessWidget {
  const InterviewPage({required this.session, super.key});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return InterviewView(session: session);
  }
}
