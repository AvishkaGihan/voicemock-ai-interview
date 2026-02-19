import 'package:voicemock/core/http/http.dart';
import 'package:voicemock/core/models/models.dart';

/// Remote data source for session API operations.
class SessionRemoteDataSource {
  SessionRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;
  final ApiClient _apiClient;

  /// Calls POST /session/start endpoint.
  ///
  /// Throws [NetworkException] on connectivity issues.
  /// Throws [ServerException] on API errors.
  Future<SessionStartResponse> startSession(
    SessionStartRequest request,
  ) async {
    final envelope = await _apiClient.post<SessionStartResponse>(
      '/session/start',
      data: request.toJson(),
      fromJson: SessionStartResponse.fromJson,
    );

    return envelope.data!;
  }

  /// Calls DELETE /session/{session_id} endpoint.
  ///
  /// Throws [NetworkException] on connectivity issues.
  /// Throws [ServerException] on API errors.
  Future<bool> deleteSession({
    required String sessionId,
    required String sessionToken,
  }) async {
    final envelope = await _apiClient.delete<DeleteSessionResponse>(
      '/session/$sessionId',
      bearerToken: sessionToken,
      fromJson: DeleteSessionResponse.fromJson,
      timeout: const Duration(seconds: 30),
    );

    return envelope.data?.deleted ?? false;
  }
}
