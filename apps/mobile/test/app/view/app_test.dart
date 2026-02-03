// Ignore for testing purposes

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/app/view/app.dart';
import 'package:voicemock/core/config/environment.dart';
import 'package:voicemock/core/http/http.dart';
import 'package:voicemock/features/interview/presentation/view/setup_page.dart';

void main() {
  group('App', () {
    testWidgets('renders SetupPage', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final apiClient = ApiClient(baseUrl: Environment.development);
      await tester.pumpWidget(App(prefs: prefs, apiClient: apiClient));
      expect(find.byType(SetupPage), findsOneWidget);
    });
  });
}
