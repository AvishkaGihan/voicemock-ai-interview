import 'package:dartz/dartz.dart';
import 'package:voicemock/core/http/http.dart';
import 'package:voicemock/core/models/models.dart';
import 'package:voicemock/features/interview/data/datasources/session_local_data_source.dart';
import 'package:voicemock/features/interview/data/datasources/session_remote_data_source.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// Repository implementation for session management.
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({
    required SessionRemoteDataSource remoteDataSource,
    required SessionLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  final SessionRemoteDataSource _remoteDataSource;
  final SessionLocalDataSource _localDataSource;

  @override
  Future<Either<InterviewFailure, Session>> startSession(
    InterviewConfig config,
  ) async {
    try {
      // Map domain config to API request
      final request = SessionStartRequest(
        role: config.role.displayName,
        interviewType: config.type.name,
        difficulty: config.difficulty.name,
        questionCount: config.questionCount,
      );

      // Call remote API
      final response = await _remoteDataSource.startSession(request);

      // Map API response to domain entity
      final session = Session(
        sessionId: response.sessionId,
        sessionToken: response.sessionToken,
        openingPrompt: response.openingPrompt,
        createdAt: DateTime.now(),
      );

      // Persist locally
      await _localDataSource.saveSession(session);

      return Right(session);
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: e.message,
          requestId: e.requestId,
        ),
      );
    } on ServerException catch (e) {
      // Check if validation error (422 or validation_error code)
      if (e.code.contains('validation')) {
        return Left(
          ValidationFailure(
            message: e.message,
            requestId: e.requestId,
          ),
        );
      }

      return Left(
        ServerFailure(
          message: e.message,
          requestId: e.requestId,
          stage: e.stage,
          retryable: e.retryable ?? false,
        ),
      );
    } on Exception catch (e) {
      return Left(
        UnknownFailure(
          message: 'An unexpected error occurred: $e',
        ),
      );
    }
  }
}
