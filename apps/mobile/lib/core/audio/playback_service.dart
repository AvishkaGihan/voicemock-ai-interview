import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;

sealed class PlaybackEvent {
  const PlaybackEvent();
}

final class PlaybackPlaying extends PlaybackEvent {
  const PlaybackPlaying();
}

final class PlaybackCompleted extends PlaybackEvent {
  const PlaybackCompleted();
}

final class PlaybackError extends PlaybackEvent {
  const PlaybackError(this.message);

  final String message;
}

class PlaybackService {
  PlaybackService({ja.AudioPlayer? audioPlayer})
    : _audioPlayer = audioPlayer,
      _enabled = true;

  PlaybackService.noop() : _audioPlayer = null, _enabled = false;

  ja.AudioPlayer? _audioPlayer;
  final bool _enabled;
  final StreamController<PlaybackEvent> _eventsController =
      StreamController<PlaybackEvent>.broadcast();

  StreamSubscription<ja.PlayerState>? _playerStateSubscription;
  StreamSubscription<ja.PlaybackEvent>? _playbackEventSubscription;

  bool get isPlaying => _audioPlayer?.playing ?? false;

  Stream<PlaybackEvent> get events => _eventsController.stream;

  Future<void> playUrl(String url, {String? bearerToken}) async {
    if (!_enabled) {
      return;
    }

    final player = _audioPlayer ??= ja.AudioPlayer();

    await stop();
    _attachPlayerListeners();

    try {
      final headers = <String, String>{
        if (bearerToken != null && bearerToken.isNotEmpty)
          'Authorization': 'Bearer $bearerToken',
      };

      await player.setAudioSource(
        ja.AudioSource.uri(
          Uri.parse(url),
          headers: headers.isEmpty ? null : headers,
        ),
      );

      _eventsController.add(const PlaybackPlaying());
      await player.play();
    } on Object catch (error) {
      _eventsController.add(PlaybackError(error.toString()));
      rethrow;
    }
  }

  Future<void> stop() async {
    final player = _audioPlayer;
    if (!_enabled || player == null) {
      return;
    }

    await _cancelPlayerSubscriptions();
    await player.stop();
  }

  Future<void> dispose() async {
    await _cancelPlayerSubscriptions();

    if (_enabled && _audioPlayer != null) {
      await _audioPlayer!.dispose();
    }

    await _eventsController.close();
  }

  void _attachPlayerListeners() {
    final player = _audioPlayer;
    if (player == null) {
      return;
    }

    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (state.processingState == ja.ProcessingState.completed) {
        _eventsController.add(const PlaybackCompleted());
      }
    });

    _playbackEventSubscription = player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace _) {
        _eventsController.add(PlaybackError(error.toString()));
      },
    );
  }

  Future<void> _cancelPlayerSubscriptions() async {
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;

    await _playbackEventSubscription?.cancel();
    _playbackEventSubscription = null;
  }
}
