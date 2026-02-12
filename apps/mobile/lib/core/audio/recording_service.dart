import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service for managing audio recording using the record package.
///
/// Wraps the AudioRecorder class to provide a testable interface
/// for recording audio in .m4a AAC format.
class RecordingService {
  /// Creates a RecordingService with optional dependencies.
  ///
  /// [recorder] - AudioRecorder instance (defaults to new AudioRecorder)
  /// [pathProvider] - Function to get recording directory
  /// (defaults to getTemporaryDirectory)
  ///
  /// This allows for dependency injection and testing.
  RecordingService({
    AudioRecorder? recorder,
    Future<Directory> Function()? pathProvider,
  }) : _recorder = recorder ?? AudioRecorder(),
       _pathProvider = pathProvider ?? getTemporaryDirectory;

  final AudioRecorder _recorder;
  final Future<Directory> Function() _pathProvider;

  /// Starts recording audio to a temporary file.
  ///
  /// The audio is recorded in .m4a AAC format with the following settings:
  /// - Encoder: AAC-LC
  /// - Sample rate: 44100 Hz
  /// - Bit rate: 128 kbps
  ///
  /// Files are saved to the app's temporary directory with the naming pattern:
  /// `voicemock_turn_{timestamp}.m4a`
  ///
  /// Throws an exception if recording fails to start.
  Future<void> startRecording() async {
    final dir = await _pathProvider();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/voicemock_turn_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(),
      path: path,
    );
  }

  /// Stops recording and returns the path to the recorded audio file.
  ///
  /// Returns null if no recording was in progress or if the recording failed.
  ///
  /// Throws an exception if stopping the recording fails.
  Future<String?> stopRecording() async {
    return _recorder.stop();
  }

  /// Returns true if currently recording, false otherwise.
  Future<bool> get isRecording => _recorder.isRecording();

  /// Deletes the recording at the specified path.
  ///
  /// Should be called when a recording is cancelled or no longer needed.
  /// Throws an exception if deletion fails, but ignores FileSystemException
  /// if the file does not exist.
  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  /// Disposes of the AudioRecorder and releases resources.
  ///
  /// Should be called when the service is no longer needed.
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
