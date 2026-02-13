import 'package:voicemock/core/http/api_client.dart';
import 'package:voicemock/core/http/exceptions.dart';
import 'package:voicemock/core/models/models.dart';

/// Remote data source for turn-related API operations.
class TurnRemoteDataSource {
  /// Creates a [TurnRemoteDataSource].
  const TurnRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// Submits a turn with audio to the backend for processing.
  ///
  /// Uploads the audio file at [audioPath] along with the [sessionId]
  /// and authenticates using [sessionToken].
  ///
  /// Returns [TurnResponseData] containing the transcript and timing info.
  ///
  /// Throws [ServerException] on API errors (auth, STT failures, etc).
  /// Throws [NetworkException] on connectivity issues.
  Future<TurnResponseData> submitTurn({
    required String audioPath,
    required String sessionId,
    required String sessionToken,
  }) async {
    final envelope = await _apiClient.postMultipart<TurnResponseData>(
      '/turn',
      filePath: audioPath,
      fileFieldName: 'audio',
      fields: {'session_id': sessionId},
      bearerToken: sessionToken,
      fromJson: TurnResponseData.fromJson,
    );

    return envelope.data!;
  }
}
