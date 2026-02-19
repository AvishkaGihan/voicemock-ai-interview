import 'package:dartz/dartz.dart';

import 'package:voicemock/features/interview/domain/failures.dart';
import 'package:voicemock/features/interview/domain/interview_config.dart';
import 'package:voicemock/features/interview/domain/session.dart';

/// Repository interface for session management operations.
abstract class SessionRepository {
  /// Starts a new interview session with the given configuration.
  ///
  /// Returns [Right(Session)] on success with session credentials
  /// and opening prompt.
  /// Returns [Left(InterviewFailure)] on any error (network,
  /// server, validation).
  ///
  /// The session token is automatically stored locally for
  /// subsequent API calls.
  Future<Either<InterviewFailure, Session>> startSession(
    InterviewConfig config,
  );

  /// Deletes a session's server-side artifacts and clears local session.
  Future<Either<InterviewFailure, bool>> deleteSession(
    String sessionId,
    String sessionToken,
  );

  /// Returns the locally stored session, if available.
  Future<Session?> getStoredSession();
}
