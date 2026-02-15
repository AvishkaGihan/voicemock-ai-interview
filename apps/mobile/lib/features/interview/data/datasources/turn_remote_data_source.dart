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
  /// Uploads the audio file at [audioPath] (if provided) or existing
  /// [transcript], along with the [sessionId].
  /// Authenticates using [sessionToken].
  ///
  /// Returns [TurnResponseData] containing the transcript and timing info.
  ///
  /// Throws [ServerException] on API errors (auth, STT failures, etc).
  /// Throws [NetworkException] on connectivity issues.
  Future<TurnResponseData> submitTurn({
    required String sessionId,
    required String sessionToken,
    String? audioPath,
    String? transcript,
  }) async {
    final fields = {'session_id': sessionId};
    if (transcript != null) {
      fields['transcript'] = transcript;
    }

    final envelope = await _apiClient.postMultipart<TurnResponseData>(
      '/turn',
      filePath: audioPath,
      fileFieldName: audioPath != null ? 'audio' : null,
      fields: fields,
      bearerToken: sessionToken,
      fromJson: TurnResponseData.fromJson,
    );

    return envelope.data!;
  }
}
