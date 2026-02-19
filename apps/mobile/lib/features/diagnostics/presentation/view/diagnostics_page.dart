/// Diagnostics page displaying per-turn timing metrics and error history.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/models/session_diagnostics.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';
import 'package:voicemock/features/diagnostics/presentation/widgets/error_summary_card.dart';
import 'package:voicemock/features/diagnostics/presentation/widgets/timing_row.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/interview_state.dart';

/// Diagnostics screen for viewing session timing and error data.
///
/// Displays:
/// - Per-turn timing breakdowns (upload, STT, LLM, total)
/// - Request IDs for each turn
/// - Last error summary (if any)
///
/// Hidden by default; accessed via settings toggle or debug mode.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  InterviewCubit? _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      // It is safe to use read() here as we just want to grab the instance
      // once to access properties or methods. However, for reactive updates,
      // we should use BlocBuilder or context.watch() in build, or
      // BlocListener. Since this page is "debug" and might not need live
      // stream updates for MVP, capturing it here is acceptable, but we'll
      // use a safer pattern below.
      _cubit = context.read<InterviewCubit>();
    } on Exception {
      _cubit = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no cubit is found, show empty state immediately.
    if (_cubit == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Diagnostics'),
          backgroundColor: VoiceMockColors.primary,
        ),
        body: _buildEmptyState(const SessionDiagnostics(sessionId: 'unknown')),
      );
    }

    // Use BlocBuilder to reactively rebuild when interview state changes.
    // Although diagnostics data isn't directly in Equatable state props
    // always, the cubit reference itself is stable.
    // Ideally, diagnostics should be part of the state or a separate stream.
    // For now, we'll rely on the fact that we might need to setState manually
    // for clear, or just rebuild when the cubit emits new states.
    return BlocBuilder<InterviewCubit, InterviewState>(
      bloc: _cubit,
      builder: (context, state) {
        final diagnostics = _cubit!.diagnostics;
        final canClear =
            diagnostics.turnRecords.isNotEmpty ||
            diagnostics.lastErrorRequestId != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Diagnostics'),
            backgroundColor: VoiceMockColors.primary,
            actions: [
              IconButton(
                tooltip: 'Clear Diagnostics',
                onPressed: canClear
                    ? () {
                        _cubit!.clearDiagnostics();
                        // Force rebuild since clearDiagnostics doesn't emit
                        // a new state in the InterviewCubit (it's internal
                        // metadata).
                        setState(() {});
                      }
                    : null,
                icon: const Icon(Icons.clear_all),
              ),
            ],
          ),
          body: diagnostics.turnRecords.isEmpty
              ? _buildEmptyState(diagnostics)
              : _buildDiagnosticsList(diagnostics),
        );
      },
    );
  }

  Widget _buildEmptyState(SessionDiagnostics diagnostics) {
    return Column(
      children: [
        _SessionIdCard(sessionId: diagnostics.sessionId),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(VoiceMockSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color:
                        VoiceMockColors.textMuted, // 0xFF94A3B8 in orig approx
                  ),
                  SizedBox(height: VoiceMockSpacing.md),
                  Text(
                    'No timing data yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: VoiceMockColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: VoiceMockSpacing.sm),
                  Text(
                    'No timing data yet — '
                    'Complete a turn to see timing metrics',
                    style: TextStyle(
                      fontSize: 14,
                      color: VoiceMockColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticsList(SessionDiagnostics diagnostics) {
    return Column(
      children: [
        _SessionIdCard(sessionId: diagnostics.sessionId),
        if (diagnostics.lastErrorRequestId != null)
          ErrorSummaryCard(
            requestId: diagnostics.lastErrorRequestId!,
            stage: diagnostics.lastErrorStage ?? 'unknown',
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(VoiceMockSpacing.md),
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

class _SessionIdCard extends StatelessWidget {
  const _SessionIdCard({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        VoiceMockSpacing.md,
        VoiceMockSpacing.md,
        VoiceMockSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Very light grey, closer to surface
        borderRadius: BorderRadius.circular(VoiceMockRadius.md),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: GestureDetector(
        onTap: () => _copySessionId(context),
        child: Row(
          children: [
            const Text(
              'Session ID: ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VoiceMockColors.textMuted,
              ),
            ),
            Expanded(
              child: Text(
                sessionId,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: VoiceMockColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.content_copy,
              size: 14,
              color: VoiceMockColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _copySessionId(BuildContext context) {
    unawaited(Clipboard.setData(ClipboardData(text: sessionId)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
