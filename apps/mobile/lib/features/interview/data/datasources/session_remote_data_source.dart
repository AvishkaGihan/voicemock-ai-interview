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
}
