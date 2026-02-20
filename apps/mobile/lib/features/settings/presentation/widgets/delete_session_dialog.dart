import 'package:flutter/material.dart';
import 'package:voicemock/core/theme/voicemock_theme.dart';

class DeleteSessionDialog extends StatelessWidget {
  const DeleteSessionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const DeleteSessionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Delete Session Data?',
        style: VoiceMockTypography.h3,
      ),
      content: Text(
        'This will permanently delete your transcripts, coaching feedback, and '
        'session summary. This cannot be undone.',
        style: VoiceMockTypography.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: VoiceMockColors.error,
            foregroundColor: VoiceMockColors.surface,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
