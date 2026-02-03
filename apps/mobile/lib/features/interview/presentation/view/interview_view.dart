import 'package:flutter/material.dart';

import 'package:voicemock/features/interview/domain/session.dart';

/// Main interview screen displaying opening prompt and interview controls.
class InterviewView extends StatelessWidget {
  const InterviewView({required this.session, super.key});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Opening prompt card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  session.openingPrompt,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Placeholder for future turn flow
            Center(
              child: Text(
                'Interview controls coming soon...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
