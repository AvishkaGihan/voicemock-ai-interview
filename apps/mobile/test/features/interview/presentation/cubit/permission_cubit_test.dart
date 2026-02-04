import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late MockPermissionService mockService;

  setUpAll(() {
    registerFallbackValue(MicrophonePermissionStatus.granted);
  });

  setUp(() {
    mockService = MockPermissionService();
  });

  group('PermissionCubit', () {
    test('initial state is denied with hasChecked = false', () async {
      final cubit = PermissionCubit(permissionService: mockService);
      expect(cubit.state.status, MicrophonePermissionStatus.denied);
      expect(cubit.state.hasChecked, false);
      expect(cubit.state.isLoading, false);
      await cubit.close();
    });

    blocTest<PermissionCubit, PermissionState>(
      'checkPermission transitions to granted when permission is granted',
      build: () {
        when(() => mockService.checkMicrophonePermission()).thenAnswer(
          (_) async => MicrophonePermissionStatus.granted,
        );
        return PermissionCubit(permissionService: mockService);
      },
      act: (cubit) => cubit.checkPermission(),
      expect: () => [
        // Loading state
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          isLoading: true,
        ),
        // Final state
        const PermissionState(
          status: MicrophonePermissionStatus.granted,
          hasChecked: true,
        ),
      ],
    );

    blocTest<PermissionCubit, PermissionState>(
      'checkPermission transitions to denied when permission is denied',
      build: () {
        when(() => mockService.checkMicrophonePermission()).thenAnswer(
          (_) async => MicrophonePermissionStatus.denied,
        );
        return PermissionCubit(permissionService: mockService);
      },
      act: (cubit) => cubit.checkPermission(),
      expect: () => [
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          isLoading: true,
        ),
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          hasChecked: true,
        ),
      ],
    );

    blocTest<PermissionCubit, PermissionState>(
      'checkPermission transitions to permanentlyDenied',
      build: () {
        when(() => mockService.checkMicrophonePermission()).thenAnswer(
          (_) async => MicrophonePermissionStatus.permanentlyDenied,
        );
        return PermissionCubit(permissionService: mockService);
      },
      act: (cubit) => cubit.checkPermission(),
      expect: () => [
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          isLoading: true,
        ),
        const PermissionState(
          status: MicrophonePermissionStatus.permanentlyDenied,
          hasChecked: true,
        ),
      ],
    );

    blocTest<PermissionCubit, PermissionState>(
      'requestPermission handles granted flow',
      build: () {
        when(() => mockService.requestMicrophonePermission()).thenAnswer(
          (_) async => MicrophonePermissionStatus.granted,
        );
        return PermissionCubit(permissionService: mockService);
      },
      act: (cubit) => cubit.requestPermission(),
      expect: () => [
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          isLoading: true,
        ),
        const PermissionState(
          status: MicrophonePermissionStatus.granted,
          hasChecked: true,
        ),
      ],
    );

    blocTest<PermissionCubit, PermissionState>(
      'requestPermission handles denied flow',
      build: () {
        when(() => mockService.requestMicrophonePermission()).thenAnswer(
          (_) async => MicrophonePermissionStatus.denied,
        );
        return PermissionCubit(permissionService: mockService);
      },
      act: (cubit) => cubit.requestPermission(),
      expect: () => [
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          isLoading: true,
        ),
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          hasChecked: true,
        ),
      ],
    );

    blocTest<PermissionCubit, PermissionState>(
      'requestPermission handles permanentlyDenied flow',
      build: () {
        when(() => mockService.requestMicrophonePermission()).thenAnswer(
          (_) async => MicrophonePermissionStatus.permanentlyDenied,
        );
        return PermissionCubit(permissionService: mockService);
      },
      act: (cubit) => cubit.requestPermission(),
      expect: () => [
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          isLoading: true,
        ),
        const PermissionState(
          status: MicrophonePermissionStatus.permanentlyDenied,
          hasChecked: true,
        ),
      ],
    );

    blocTest<PermissionCubit, PermissionState>(
      'checkPermission handles exceptions gracefully',
      build: () {
        when(
          () => mockService.checkMicrophonePermission(),
        ).thenThrow(Exception('Test error'));
        return PermissionCubit(permissionService: mockService);
      },
      act: (cubit) => cubit.checkPermission(),
      expect: () => [
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          isLoading: true,
        ),
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          hasChecked: true,
        ),
      ],
    );

    blocTest<PermissionCubit, PermissionState>(
      'requestPermission handles exceptions gracefully',
      build: () {
        when(
          () => mockService.requestMicrophonePermission(),
        ).thenThrow(Exception('Test error'));
        return PermissionCubit(permissionService: mockService);
      },
      act: (cubit) => cubit.requestPermission(),
      expect: () => [
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          isLoading: true,
        ),
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
          hasChecked: true,
        ),
      ],
    );

    test('openSettings calls permissionService.openAppSettings', () async {
      when(() => mockService.openAppSettings()).thenAnswer((_) async => true);

      final cubit = PermissionCubit(permissionService: mockService);
      final result = await cubit.openSettings();

      expect(result, true);
      verify(() => mockService.openAppSettings()).called(1);

      await cubit.close();
    });
  });

  group('PermissionState', () {
    test('initial factory creates correct state', () {
      final state = PermissionState.initial();
      expect(state.status, MicrophonePermissionStatus.denied);
      expect(state.isLoading, false);
      expect(state.hasChecked, false);
    });

    test('isGranted returns true only when status is granted', () {
      expect(
        const PermissionState(
          status: MicrophonePermissionStatus.granted,
        ).isGranted,
        true,
      );
      expect(
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
        ).isGranted,
        false,
      );
    });

    test('isDenied returns true only when status is denied', () {
      expect(
        const PermissionState(
          status: MicrophonePermissionStatus.denied,
        ).isDenied,
        true,
      );
      expect(
        const PermissionState(
          status: MicrophonePermissionStatus.permanentlyDenied,
        ).isDenied,
        false,
      );
    });

    test(
      'isPermanentlyDenied returns true only when permanentlyDenied',
      () {
        expect(
          const PermissionState(
            status: MicrophonePermissionStatus.permanentlyDenied,
          ).isPermanentlyDenied,
          true,
        );
        expect(
          const PermissionState(
            status: MicrophonePermissionStatus.denied,
          ).isPermanentlyDenied,
          false,
        );
      },
    );

    test('copyWith creates correct copy', () {
      const state = PermissionState(
        status: MicrophonePermissionStatus.denied,
      );

      final copied = state.copyWith(
        status: MicrophonePermissionStatus.granted,
        isLoading: true,
        hasChecked: true,
      );

      expect(copied.status, MicrophonePermissionStatus.granted);
      expect(copied.isLoading, true);
      expect(copied.hasChecked, true);
    });

    test('props returns correct list', () {
      const state = PermissionState(
        status: MicrophonePermissionStatus.granted,
        isLoading: true,
        hasChecked: true,
      );

      expect(
        state.props,
        [MicrophonePermissionStatus.granted, true, true],
      );
    });
  });
}
