import 'package:voicemock/app/app.dart';
import 'package:voicemock/bootstrap.dart';

Future<void> main() async {
  await bootstrap((prefs) => App(prefs: prefs));
}
