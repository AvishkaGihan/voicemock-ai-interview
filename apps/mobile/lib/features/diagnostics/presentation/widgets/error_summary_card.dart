/// Widget displaying last error summary with request ID and stage.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays the last error's request ID and stage.
///
/// Shown at the top of diagnostics when an error has occurred.
/// Allows copying request ID for troubleshooting.
class ErrorSummaryCard extends StatelessWidget {
  const ErrorSummaryCard({
    required this.requestId,
    required this.stage,
    super.key,
  });

  final String requestId;
  final String stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Last Error',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stage
          Row(
            children: [
              const Text(
                'Stage: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF991B1B),
                ),
              ),
              Text(
                stage.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Request ID (tap to copy)
          GestureDetector(
            onTap: () => _copyRequestId(context),
            child: Row(
              children: [
                const Icon(
                  Icons.tag,
                  size: 14,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    requestId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFFDC2626),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.content_copy,
                  size: 14,
                  color: Color(0xFFDC2626),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyRequestId(BuildContext context) {
    unawaited(Clipboard.setData(ClipboardData(text: requestId)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
