import 'package:flutter_test/flutter_test.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

void main() {
  group('InterviewStage', () {
    test('should have all required stage values', () {
      const stages = InterviewStage.values;

      expect(stages, contains(InterviewStage.ready));
      expect(stages, contains(InterviewStage.recording));
      expect(stages, contains(InterviewStage.uploading));
      expect(stages, contains(InterviewStage.transcribing));
      expect(stages, contains(InterviewStage.thinking));
      expect(stages, contains(InterviewStage.speaking));
      expect(stages, contains(InterviewStage.error));
      expect(stages.length, 7);
    });

    test('toString should return stage name for logging', () {
      expect(InterviewStage.ready.toString(), contains('ready'));
      expect(InterviewStage.recording.toString(), contains('recording'));
      expect(InterviewStage.uploading.toString(), contains('uploading'));
      expect(InterviewStage.transcribing.toString(), contains('transcribing'));
      expect(InterviewStage.thinking.toString(), contains('thinking'));
      expect(InterviewStage.speaking.toString(), contains('speaking'));
      expect(InterviewStage.error.toString(), contains('error'));
    });

    group('isProcessing', () {
      test('should return true for processing stages', () {
        expect(InterviewStage.uploading.isProcessing, true);
        expect(InterviewStage.transcribing.isProcessing, true);
        expect(InterviewStage.thinking.isProcessing, true);
      });

      test('should return false for non-processing stages', () {
        expect(InterviewStage.ready.isProcessing, false);
        expect(InterviewStage.recording.isProcessing, false);
        expect(InterviewStage.speaking.isProcessing, false);
        expect(InterviewStage.error.isProcessing, false);
      });
    });

    group('isUserTurn', () {
      test('should return true when user can interact', () {
        expect(InterviewStage.ready.isUserTurn, true);
        expect(InterviewStage.recording.isUserTurn, true);
      });

      test('should return false when user cannot interact', () {
        expect(InterviewStage.uploading.isUserTurn, false);
        expect(InterviewStage.transcribing.isUserTurn, false);
        expect(InterviewStage.thinking.isUserTurn, false);
        expect(InterviewStage.speaking.isUserTurn, false);
        expect(InterviewStage.error.isUserTurn, false);
      });
    });

    group('isCoachTurn', () {
      test('should return true when coach is speaking', () {
        expect(InterviewStage.speaking.isCoachTurn, true);
      });

      test('should return false when coach is not speaking', () {
        expect(InterviewStage.ready.isCoachTurn, false);
        expect(InterviewStage.recording.isCoachTurn, false);
        expect(InterviewStage.uploading.isCoachTurn, false);
        expect(InterviewStage.transcribing.isCoachTurn, false);
        expect(InterviewStage.thinking.isCoachTurn, false);
        expect(InterviewStage.error.isCoachTurn, false);
      });
    });
  });
}
