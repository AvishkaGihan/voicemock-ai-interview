import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:voicemock/features/diagnostics/presentation/view/diagnostics_page.dart';
import 'package:voicemock/features/interview/domain/session.dart';
import 'package:voicemock/features/interview/presentation/view/interview_page.dart';
import 'package:voicemock/features/interview/presentation/view/permission_rationale_page.dart';
import 'package:voicemock/features/interview/presentation/view/setup_page.dart';

/// App router configuration using go_router.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const SetupPage(),
    ),
    GoRoute(
      path: PermissionRationalePage.routeName,
      name: 'permission',
      builder: (context, state) => const PermissionRationalePage(),
    ),
    GoRoute(
      path: '/interview',
      name: 'interview',
      builder: (context, state) {
        final session = state.extra as Session?;
        if (session == null) {
          return const Scaffold(
            body: Center(
              child: Text('Error: No session provided'),
            ),
          );
        }
        return InterviewPage(session: session);
      },
    ),
    GoRoute(
      path: '/diagnostics',
      name: 'diagnostics',
      builder: (context, state) => const DiagnosticsPage(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);
