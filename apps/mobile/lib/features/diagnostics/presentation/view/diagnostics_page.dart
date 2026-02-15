/// Diagnostics page displaying per-turn timing metrics and error history.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/models/session_diagnostics.dart';
import 'package:voicemock/features/diagnostics/presentation/widgets/error_summary_card.dart';
import 'package:voicemock/features/diagnostics/presentation/widgets/timing_row.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';

/// Diagnostics screen for viewing session timing and error data.
///
/// Displays:
/// - Per-turn timing breakdowns (upload, STT, LLM, total)
/// - Request IDs for each turn
/// - Last error summary (if any)
///
/// Hidden by default; accessed via settings toggle or debug mode.
class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InterviewCubit>();
    final diagnostics = cubit.diagnostics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        backgroundColor: const Color(0xFF2F6FED),
      ),
      body: diagnostics.turnRecords.isEmpty
          ? _buildEmptyState()
          : _buildDiagnosticsList(diagnostics),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'No timing data yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete a turn to see timing metrics',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsList(SessionDiagnostics diagnostics) {
    return Column(
      children: [
        // Error summary card (if error exists)
        if (diagnostics.lastErrorRequestId != null)
          ErrorSummaryCard(
            requestId: diagnostics.lastErrorRequestId!,
            stage: diagnostics.lastErrorStage ?? 'unknown',
          ),
        // Turn timing records
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: diagnostics.turnRecords.length,
            itemBuilder: (context, index) {
              final record = diagnostics.turnRecords[index];
              return TimingRow(record: record);
            },
          ),
        ),
      ],
    );
  }
}
