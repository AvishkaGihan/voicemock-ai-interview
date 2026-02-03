// Ignore for testing purposes

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/app/app.dart';
import 'package:voicemock/features/interview/presentation/view/setup_page.dart';

void main() {
  group('App', () {
    testWidgets('renders SetupPage', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(App(prefs: prefs));
      expect(find.byType(SetupPage), findsOneWidget);
    });
  });
}
