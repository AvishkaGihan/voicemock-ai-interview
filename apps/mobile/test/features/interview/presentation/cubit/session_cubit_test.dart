import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_state.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late SessionRepository repository;
  late SessionCubit cubit;

  setUp(() {
    repository = MockSessionRepository();
    cubit = SessionCubit(repository: repository);
  });

  tearDown(() {
    unawaited(cubit.close());
  });

  group('SessionCubit', () {
    const config = InterviewConfig(
      role: InterviewRole.softwareEngineer,
      type: InterviewType.behavioral,
      difficulty: DifficultyLevel.medium,
      questionCount: 5,
    );

    final session = Session(
      sessionId: 'session-123',
      sessionToken: 'token-abc',
      openingPrompt: 'Welcome!',
      createdAt: DateTime(2026, 2, 3),
    );

    test('initial state is SessionInitial', () {
      expect(cubit.state, isA<SessionInitial>());
    });

    blocTest<SessionCubit, SessionState>(
      'emits [SessionLoading, SessionSuccess] on successful start',
      build: () {
        when(
          () => repository.startSession(config),
        ).thenAnswer((_) async => Right(session));
        return cubit;
      },
      act: (cubit) => cubit.startSession(config),
      expect: () => [
        isA<SessionLoading>(),
        isA<SessionSuccess>()
            .having((s) => s.session.sessionId, 'sessionId', 'session-123')
            .having((s) => s.session.sessionToken, 'sessionToken', 'token-abc')
            .having(
              (s) => s.session.openingPrompt,
              'openingPrompt',
              'Welcome!',
            ),
      ],
      verify: (_) {
        verify(() => repository.startSession(config)).called(1);
      },
    );

    blocTest<SessionCubit, SessionState>(
      'emits [SessionLoading, SessionFailure] on network error',
      build: () {
        when(() => repository.startSession(config)).thenAnswer(
          (_) async => const Left(
            NetworkFailure(
              message: 'No internet connection',
              requestId: 'req-123',
            ),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.startSession(config),
      expect: () => [
        isA<SessionLoading>(),
        isA<SessionFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>()
              .having((f) => f.message, 'message', 'No internet connection')
              .having((f) => f.requestId, 'requestId', 'req-123')
              .having((f) => f.retryable, 'retryable', isTrue),
        ),
      ],
      verify: (_) {
        verify(() => repository.startSession(config)).called(1);
      },
    );

    blocTest<SessionCubit, SessionState>(
      'emits [SessionLoading, SessionFailure] on server error',
      build: () {
        when(() => repository.startSession(config)).thenAnswer(
          (_) async => const Left(
            ServerFailure(
              message: 'Internal server error',
              requestId: 'req-456',
              stage: 'unknown',
            ),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.startSession(config),
      expect: () => [
        isA<SessionLoading>(),
        isA<SessionFailure>().having(
          (s) => s.failure,
          'failure',
          isA<ServerFailure>()
              .having((f) => f.message, 'message', 'Internal server error')
              .having((f) => f.retryable, 'retryable', isFalse),
        ),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'emits [SessionLoading, SessionFailure] on validation error',
      build: () {
        when(() => repository.startSession(config)).thenAnswer(
          (_) async => const Left(
            ValidationFailure(
              message: 'Invalid difficulty level',
              requestId: 'req-789',
              details: {'field': 'difficulty'},
            ),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.startSession(config),
      expect: () => [
        isA<SessionLoading>(),
        isA<SessionFailure>().having(
          (s) => s.failure,
          'failure',
          isA<ValidationFailure>()
              .having(
                (f) => f.message,
                'message',
                'Invalid difficulty level',
              )
              .having((f) => f.retryable, 'retryable', isFalse),
        ),
      ],
    );
  });
}
