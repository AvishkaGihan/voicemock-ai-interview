import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/connectivity/connectivity.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityCubit cubit;

  setUp(() {
    mockConnectivity = MockConnectivity();
    cubit = ConnectivityCubit(connectivity: mockConnectivity);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('ConnectivityCubit', () {
    test('initial state is ConnectivityInitial', () {
      expect(cubit.state, equals(const ConnectivityInitial()));
    });

    group('checkConnectivity', () {
      blocTest<ConnectivityCubit, ConnectivityState>(
        'emits ConnectivityOnline when wifi connected',
        build: () {
          when(
            () => mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.wifi]);
          return cubit;
        },
        act: (cubit) => cubit.checkConnectivity(),
        expect: () => [const ConnectivityOnline()],
        verify: (_) {
          verify(() => mockConnectivity.checkConnectivity()).called(1);
        },
      );

      blocTest<ConnectivityCubit, ConnectivityState>(
        'emits ConnectivityOnline when mobile connected',
        build: () {
          when(
            () => mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.mobile]);
          return cubit;
        },
        act: (cubit) => cubit.checkConnectivity(),
        expect: () => [const ConnectivityOnline()],
      );

      blocTest<ConnectivityCubit, ConnectivityState>(
        'emits ConnectivityOnline when ethernet connected',
        build: () {
          when(
            () => mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.ethernet]);
          return cubit;
        },
        act: (cubit) => cubit.checkConnectivity(),
        expect: () => [const ConnectivityOnline()],
      );

      blocTest<ConnectivityCubit, ConnectivityState>(
        'emits ConnectivityOffline when no connection',
        build: () {
          when(
            () => mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.none]);
          return cubit;
        },
        act: (cubit) => cubit.checkConnectivity(),
        expect: () => [const ConnectivityOffline()],
      );

      blocTest<ConnectivityCubit, ConnectivityState>(
        'emits ConnectivityOnline when multiple connections active',
        build: () {
          when(() => mockConnectivity.checkConnectivity()).thenAnswer(
            (_) async => [
              ConnectivityResult.wifi,
              ConnectivityResult.vpn,
            ],
          );
          return cubit;
        },
        act: (cubit) => cubit.checkConnectivity(),
        expect: () => [const ConnectivityOnline()],
      );

      blocTest<ConnectivityCubit, ConnectivityState>(
        'emits ConnectivityOnline when mixed results with one non-none',
        build: () {
          when(() => mockConnectivity.checkConnectivity()).thenAnswer(
            (_) async => [
              ConnectivityResult.none,
              ConnectivityResult.mobile,
            ],
          );
          return cubit;
        },
        act: (cubit) => cubit.checkConnectivity(),
        expect: () => [const ConnectivityOnline()],
      );
    });

    group('startListening', () {
      blocTest<ConnectivityCubit, ConnectivityState>(
        'emits states on connectivity stream changes',
        build: () {
          when(() => mockConnectivity.onConnectivityChanged).thenAnswer(
            (_) => Stream.fromIterable([
              [ConnectivityResult.wifi],
              [ConnectivityResult.none],
              [ConnectivityResult.mobile],
            ]),
          );
          return cubit;
        },
        act: (cubit) => cubit.startListening(),
        expect: () => [
          const ConnectivityOnline(),
          const ConnectivityOffline(),
          const ConnectivityOnline(),
        ],
      );

      blocTest<ConnectivityCubit, ConnectivityState>(
        'handles rapid connectivity changes',
        build: () {
          when(() => mockConnectivity.onConnectivityChanged).thenAnswer(
            (_) => Stream.fromIterable([
              [ConnectivityResult.wifi],
              [ConnectivityResult.none],
              [ConnectivityResult.wifi],
              [ConnectivityResult.none],
              [ConnectivityResult.mobile],
            ]),
          );
          return cubit;
        },
        act: (cubit) => cubit.startListening(),
        expect: () => [
          const ConnectivityOnline(),
          const ConnectivityOffline(),
          const ConnectivityOnline(),
          const ConnectivityOffline(),
          const ConnectivityOnline(),
        ],
      );
    });

    group('stopListening', () {
      test('cancels subscription', () async {
        final controller =
            StreamController<List<ConnectivityResult>>.broadcast();

        when(
          () => mockConnectivity.onConnectivityChanged,
        ).thenAnswer((_) => controller.stream);

        cubit.startListening();
        expect(controller.hasListener, isTrue);

        await cubit.stopListening();
        await Future<void>.delayed(Duration.zero);
        expect(controller.hasListener, isFalse);

        await controller.close();
      });
    });

    group('close', () {
      test('cancels subscription before closing', () async {
        final controller =
            StreamController<List<ConnectivityResult>>.broadcast();

        when(
          () => mockConnectivity.onConnectivityChanged,
        ).thenAnswer((_) => controller.stream);

        cubit.startListening();
        expect(controller.hasListener, isTrue);

        await cubit.close();
        expect(controller.hasListener, isFalse);

        await controller.close();
      });
    });
  });
}
