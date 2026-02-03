import 'package:voicemock/app/view/app.dart';
import 'package:voicemock/bootstrap.dart';

Future<void> main() async {
  await bootstrap((prefs) => App(prefs: prefs));
}
