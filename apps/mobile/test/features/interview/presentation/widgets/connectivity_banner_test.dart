import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/connectivity/connectivity.dart';
import 'package:voicemock/features/interview/presentation/widgets/connectivity_banner.dart';

import '../../../../helpers/pump_app.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

void main() {
  late MockConnectivityCubit mockConnectivityCubit;

  setUp(() {
    mockConnectivityCubit = MockConnectivityCubit();
    when(
      () => mockConnectivityCubit.state,
    ).thenReturn(const ConnectivityOffline());
    when(
      () => mockConnectivityCubit.checkConnectivity(),
    ).thenAnswer((_) async {});
  });

  group('ConnectivityBanner', () {
    testWidgets('displays correct message text', (tester) async {
      await tester.pumpApp(
        const ConnectivityBanner(),
        connectivityCubit: mockConnectivityCubit,
      );

      expect(
        find.text('Internet connection required to start interview'),
        findsOneWidget,
      );
    });

    testWidgets('displays wifi_off icon', (tester) async {
      await tester.pumpApp(
        const ConnectivityBanner(),
        connectivityCubit: mockConnectivityCubit,
      );

      final iconFinder = find.byIcon(Icons.wifi_off);
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.size, equals(20));
    });

    testWidgets('displays Retry button', (tester) async {
      await tester.pumpApp(
        const ConnectivityBanner(),
        connectivityCubit: mockConnectivityCubit,
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Retry'),
        findsOneWidget,
      );
    });

    testWidgets('Retry button triggers connectivity check', (tester) async {
      await tester.pumpApp(
        const ConnectivityBanner(),
        connectivityCubit: mockConnectivityCubit,
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => mockConnectivityCubit.checkConnectivity()).called(1);
    });

    testWidgets('has correct orange warning styling', (tester) async {
      await tester.pumpApp(
        const ConnectivityBanner(),
        connectivityCubit: mockConnectivityCubit,
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(Colors.orange[100]));

      final border = decoration.border! as Border;
      expect(border.bottom.color, equals(Colors.orange[300]));
      expect(border.bottom.width, equals(1));
    });

    testWidgets('displays full width', (tester) async {
      await tester.pumpApp(
        const ConnectivityBanner(),
        connectivityCubit: mockConnectivityCubit,
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(container.constraints?.maxWidth, equals(double.infinity));
    });

    testWidgets('has correct padding', (tester) async {
      await tester.pumpApp(
        const ConnectivityBanner(),
        connectivityCubit: mockConnectivityCubit,
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );

      expect(
        container.padding,
        equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      );
    });
  });
}
