import 'package:json_annotation/json_annotation.dart';

part 'turn_models.g.dart';

/// Response data from POST /turn containing transcript and metadata.
@JsonSerializable()
class TurnResponseData {
  /// Creates a [TurnResponseData].
  const TurnResponseData({
    required this.transcript,
    required this.timings,
    this.assistantText,
    this.ttsAudioUrl,
  });

  /// Creates a [TurnResponseData] from JSON.
  factory TurnResponseData.fromJson(Map<String, dynamic> json) =>
      _$TurnResponseDataFromJson(json);

  /// The transcribed text from the user's audio.
  final String transcript;

  /// The assistant's text response (null until LLM is integrated).
  @JsonKey(name: 'assistant_text')
  final String? assistantText;

  /// URL to the TTS audio file (null until TTS is integrated).
  @JsonKey(name: 'tts_audio_url')
  final String? ttsAudioUrl;

  /// Timing information for each processing stage in milliseconds.
  final Map<String, double> timings;

  /// Converts this [TurnResponseData] to JSON.
  Map<String, dynamic> toJson() => _$TurnResponseDataToJson(this);
}
