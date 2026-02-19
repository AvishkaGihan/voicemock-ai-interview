import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/settings/presentation/widgets/delete_session_dialog.dart';

void main() {
  group('DeleteSessionDialog', () {
    testWidgets('renders copy and actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DeleteSessionDialog()),
        ),
      );

      expect(find.text('Delete Session Data?'), findsOneWidget);
      expect(
        find.text(
          'This will permanently delete your transcripts, coaching feedback, '
          'and session summary. This cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirm returns true and cancel returns false', (
      tester,
    ) async {
      Future<bool?> openDialogAndTap(String label) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await DeleteSessionDialog.show(context);
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        return result;
      }

      expect(await openDialogAndTap('Delete'), isTrue);
      expect(await openDialogAndTap('Cancel'), isFalse);
    });
  });
}
