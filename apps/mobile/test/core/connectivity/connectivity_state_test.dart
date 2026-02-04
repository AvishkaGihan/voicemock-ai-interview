import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/core/connectivity/connectivity_state.dart';

void main() {
  group('ConnectivityState', () {
    group('ConnectivityInitial', () {
      test('supports value equality', () {
        expect(
          const ConnectivityInitial(),
          equals(const ConnectivityInitial()),
        );
      });

      test('props are empty', () {
        expect(const ConnectivityInitial().props, isEmpty);
      });

      test('toString returns correct value', () {
        expect(
          const ConnectivityInitial().toString(),
          equals('ConnectivityInitial'),
        );
      });
    });

    group('ConnectivityOnline', () {
      test('supports value equality', () {
        expect(
          const ConnectivityOnline(),
          equals(const ConnectivityOnline()),
        );
      });

      test('props are empty', () {
        expect(const ConnectivityOnline().props, isEmpty);
      });

      test('toString returns correct value', () {
        expect(
          const ConnectivityOnline().toString(),
          equals('ConnectivityOnline'),
        );
      });
    });

    group('ConnectivityOffline', () {
      test('supports value equality', () {
        expect(
          const ConnectivityOffline(),
          equals(const ConnectivityOffline()),
        );
      });

      test('props are empty', () {
        expect(const ConnectivityOffline().props, isEmpty);
      });

      test('toString returns correct value', () {
        expect(
          const ConnectivityOffline().toString(),
          equals('ConnectivityOffline'),
        );
      });
    });

    test('different states are not equal', () {
      expect(
        const ConnectivityOnline(),
        isNot(equals(const ConnectivityOffline())),
      );
      expect(
        const ConnectivityInitial(),
        isNot(equals(const ConnectivityOnline())),
      );
      expect(
        const ConnectivityInitial(),
        isNot(equals(const ConnectivityOffline())),
      );
    });
  });
}
