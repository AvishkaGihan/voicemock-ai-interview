import 'package:voicemock/app/view/app.dart';
import 'package:voicemock/bootstrap.dart';
import 'package:voicemock/core/config/environment.dart';

Future<void> main() async {
  await bootstrap(
    (prefs, apiClient) => App(prefs: prefs, apiClient: apiClient),
    baseUrl: Environment.staging,
  );
}
