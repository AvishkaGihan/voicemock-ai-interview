import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';
import 'package:voicemock/features/interview/presentation/view/permission_rationale_view.dart';

class MockPermissionCubit extends MockCubit<PermissionState>
    implements PermissionCubit {}

extension on WidgetTester {
  Future<void> pumpPermissionRationaleView(PermissionCubit cubit) async {
    final router = GoRouter(
      initialLocation: '/permission',
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const Scaffold(
            body: Text('Home Screen'),
          ),
        ),
        GoRoute(
          path: '/permission',
          builder: (context, state) => BlocProvider<PermissionCubit>.value(
            value: cubit,
            child: const PermissionRationaleView(),
          ),
        ),
      ],
    );

    await pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
  }
}

void main() {
  late MockPermissionCubit mockCubit;

  setUpAll(() {
    registerFallbackValue(MicrophonePermissionStatus.granted);
  });

  setUp(() {
    mockCubit = MockPermissionCubit();
    when(() => mockCubit.state).thenReturn(PermissionState.initial());
  });

  group('PermissionRationaleView', () {
    testWidgets('renders rationale headline text', (tester) async {
      await tester.pumpPermissionRationaleView(mockCubit);

      expect(
        find.text('VoiceMock needs microphone access'),
        findsOneWidget,
      );
    });

    testWidgets('renders rationale body text', (tester) async {
      await tester.pumpPermissionRationaleView(mockCubit);

      expect(
        find.textContaining('To practice interview answers with your voice'),
        findsOneWidget,
      );
    });

    testWidgets('renders microphone icon', (tester) async {
      await tester.pumpPermissionRationaleView(mockCubit);

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('renders Allow Microphone Access button', (tester) async {
      await tester.pumpPermissionRationaleView(mockCubit);

      expect(find.text('Allow Microphone Access'), findsOneWidget);
    });

    testWidgets('renders Not now button', (tester) async {
      await tester.pumpPermissionRationaleView(mockCubit);

      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets(
      'tapping Allow Microphone Access triggers permission request',
      (tester) async {
        when(() => mockCubit.requestPermission()).thenAnswer((_) async {});

        await tester.pumpPermissionRationaleView(mockCubit);

        await tester.tap(find.text('Allow Microphone Access'));
        await tester.pump();

        verify(() => mockCubit.requestPermission()).called(1);
      },
    );

    testWidgets('tapping Not now navigates back to home', (tester) async {
      await tester.pumpPermissionRationaleView(mockCubit);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets(
      'shows loading indicator when isLoading is true',
      (tester) async {
        when(() => mockCubit.state).thenReturn(
          const PermissionState(
            status: MicrophonePermissionStatus.denied,
            isLoading: true,
          ),
        );

        await tester.pumpPermissionRationaleView(mockCubit);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'button is disabled when isLoading is true',
      (tester) async {
        when(() => mockCubit.state).thenReturn(
          const PermissionState(
            status: MicrophonePermissionStatus.denied,
            isLoading: true,
          ),
        );

        await tester.pumpPermissionRationaleView(mockCubit);

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'navigates to home when permission is granted',
      (tester) async {
        final statesController = StreamController<PermissionState>.broadcast();

        when(() => mockCubit.stream).thenAnswer(
          (_) => statesController.stream,
        );
        when(() => mockCubit.state).thenReturn(PermissionState.initial());

        await tester.pumpPermissionRationaleView(mockCubit);

        // Simulate permission granted
        statesController.add(
          const PermissionState(
            status: MicrophonePermissionStatus.granted,
            hasChecked: true,
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Home Screen'), findsOneWidget);

        await statesController.close();
      },
    );
  });
}
