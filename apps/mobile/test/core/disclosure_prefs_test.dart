import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicemock/core/storage/disclosure_prefs.dart';

void main() {
  group('DisclosurePrefs', () {
    late SharedPreferences prefs;
    late DisclosurePrefs disclosurePrefs;

    setUp(() async {
      // Use a clean in-memory store for each test.
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      disclosurePrefs = DisclosurePrefs(prefs);
    });

    // 7.1 — returns false by default (key absent from store)
    test('hasAcknowledgedDisclosure returns false by default', () async {
      expect(await disclosurePrefs.hasAcknowledgedDisclosure(), isFalse);
    });

    // 7.2 — acknowledgeDisclosure persists the value
    test('acknowledgeDisclosure persists the acknowledgment', () async {
      await disclosurePrefs.acknowledgeDisclosure();

      // Verify the value is stored under the versioned key.
      expect(
        prefs.getBool('disclosure_acknowledged_v1'),
        isTrue,
      );
    });

    // 7.3 — hasAcknowledgedDisclosure returns true after acknowledgment
    test(
      'hasAcknowledgedDisclosure returns true after acknowledgeDisclosure is '
      'called',
      () async {
        await disclosurePrefs.acknowledgeDisclosure();

        expect(await disclosurePrefs.hasAcknowledgedDisclosure(), isTrue);
      },
    );

    // Extra: re-creating DisclosurePrefs with same prefs instance reads
    // persisted value (simulates app restart).
    test('acknowledgment survives DisclosurePrefs re-instantiation with same '
        'prefs', () async {
      await disclosurePrefs.acknowledgeDisclosure();

      final newDisclosurePrefs = DisclosurePrefs(prefs);
      expect(await newDisclosurePrefs.hasAcknowledgedDisclosure(), isTrue);
    });
  });
}
