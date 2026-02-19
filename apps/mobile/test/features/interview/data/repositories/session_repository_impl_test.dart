import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/http/http.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/features/interview/data/data.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

class MockSessionRemoteDataSource extends Mock
    implements SessionRemoteDataSource {}

class MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

void main() {
  late SessionRemoteDataSource remoteDataSource;
  late SessionLocalDataSource localDataSource;
  late SessionRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockSessionRemoteDataSource();
    localDataSource = MockSessionLocalDataSource();
    repository = SessionRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  });

  setUpAll(() {
    registerFallbackValue(
      Session(
        sessionId: '',
        sessionToken: '',
        openingPrompt: '',
        totalQuestions: 5,
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      const SessionStartRequest(
        role: '',
        interviewType: '',
        difficulty: '',
        questionCount: 0,
      ),
    );
  });

  group('SessionRepositoryImpl', () {
    const config = InterviewConfig(
      role: InterviewRole.softwareEngineer,
      type: InterviewType.behavioral,
      difficulty: DifficultyLevel.medium,
      questionCount: 5,
    );

    const response = SessionStartResponse(
      sessionId: 'session-123',
      sessionToken: 'token-abc',
      openingPrompt: 'Welcome to the interview!',
    );

    test('returns Right(Session) on success', () async {
      when(
        () => remoteDataSource.startSession(any()),
      ).thenAnswer((_) async => response);
      when(
        () => localDataSource.saveSession(any()),
      ).thenAnswer((_) async => {});

      final result = await repository.startSession(config);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left($failure)'),
        (session) {
          expect(session.sessionId, 'session-123');
          expect(session.sessionToken, 'token-abc');
          expect(session.openingPrompt, 'Welcome to the interview!');
        },
      );
    });

    test('saves session locally on success', () async {
      when(
        () => remoteDataSource.startSession(any()),
      ).thenAnswer((_) async => response);
      when(
        () => localDataSource.saveSession(any()),
      ).thenAnswer((_) async => {});

      await repository.startSession(config);

      verify(() => localDataSource.saveSession(any())).called(1);
    });

    test('returns Left(NetworkFailure) on NetworkException', () async {
      when(() => remoteDataSource.startSession(any())).thenThrow(
        NetworkException(
          message: 'Connection timeout',
          requestId: 'req-123',
        ),
      );

      final result = await repository.startSession(config);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, 'Connection timeout');
          expect(failure.requestId, 'req-123');
          expect(failure.retryable, isTrue);
        },
        (session) => fail('Expected Left but got Right($session)'),
      );
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => remoteDataSource.startSession(any())).thenThrow(
        ServerException(
          message: 'Internal server error',
          code: 'internal_error',
          stage: 'unknown',
          retryable: false,
          requestId: 'req-456',
        ),
      );

      final result = await repository.startSession(config);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Internal server error');
          expect(failure.requestId, 'req-456');
          expect(failure.retryable, isFalse);
        },
        (session) => fail('Expected Left but got Right($session)'),
      );
    });

    test(
      'returns Left(ValidationFailure) on validation ServerException',
      () async {
        when(() => remoteDataSource.startSession(any())).thenThrow(
          ServerException(
            message: 'Invalid difficulty',
            code: 'validation_error',
            requestId: 'req-789',
          ),
        );

        final result = await repository.startSession(config);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Invalid difficulty');
            expect(failure.retryable, isFalse);
          },
          (session) => fail('Expected Left but got Right($session)'),
        );
      },
    );

    test('returns Left(UnknownFailure) on unexpected exception', () async {
      when(
        () => remoteDataSource.startSession(any()),
      ).thenThrow(Exception('Unexpected error'));

      final result = await repository.startSession(config);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          expect(failure.message, contains('Unexpected error'));
        },
        (session) => fail('Expected Left but got Right($session)'),
      );
    });

    test('converts config to correct request format', () async {
      when(
        () => remoteDataSource.startSession(any()),
      ).thenAnswer((_) async => response);
      when(
        () => localDataSource.saveSession(any()),
      ).thenAnswer((_) async => {});

      await repository.startSession(config);

      final captured =
          verify(
                () => remoteDataSource.startSession(captureAny()),
              ).captured.single
              as SessionStartRequest;

      expect(captured.role, 'Software Engineer');
      expect(captured.interviewType, 'behavioral');
      expect(captured.difficulty, 'medium');
      expect(captured.questionCount, 5);
    });

    test(
      'deleteSession returns Right(true) and clears local session',
      () async {
        when(
          () => remoteDataSource.deleteSession(
            sessionId: any(named: 'sessionId'),
            sessionToken: any(named: 'sessionToken'),
          ),
        ).thenAnswer((_) async => true);
        when(localDataSource.clearSession).thenAnswer((_) async {});

        final result = await repository.deleteSession(
          'session-123',
          'token-abc',
        );

        expect(result.isRight(), isTrue);
        verify(
          () => remoteDataSource.deleteSession(
            sessionId: 'session-123',
            sessionToken: 'token-abc',
          ),
        ).called(1);
        verify(localDataSource.clearSession).called(1);
      },
    );

    test(
      'deleteSession maps 404 to success (idempotent) and clears local',
      () async {
        when(
          () => remoteDataSource.deleteSession(
            sessionId: any(named: 'sessionId'),
            sessionToken: any(named: 'sessionToken'),
          ),
        ).thenThrow(
          ServerException(
            message: 'Session not found or already deleted.',
            code: 'session_not_found',
            requestId: 'req-delete-1',
            retryable: false,
          ),
        );
        when(localDataSource.clearSession).thenAnswer((_) async {});

        final result = await repository.deleteSession('missing', 'token');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left($failure)'),
          (success) => expect(success, isTrue),
        );
        verify(localDataSource.clearSession).called(1);
      },
    );

    test('getStoredSession proxies local data source', () async {
      final session = Session(
        sessionId: 'session-local',
        sessionToken: 'token-local',
        openingPrompt: 'Hello',
        totalQuestions: 5,
        createdAt: DateTime.now(),
      );
      when(localDataSource.getSession).thenAnswer((_) async => session);

      final result = await repository.getStoredSession();

      expect(result, session);
      verify(localDataSource.getSession).called(1);
    });
  });
}
