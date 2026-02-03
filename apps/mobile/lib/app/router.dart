import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    // Placeholder for future interview route
    GoRoute(
      path: '/interview',
      name: 'interview',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('Interview Screen - Coming in Story 2.1'),
        ),
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri.path}'),
    ),
  ),
);
