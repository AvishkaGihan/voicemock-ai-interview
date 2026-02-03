/// Difficulty levels for interview practice sessions.
///
/// Controls the complexity and challenge of interview questions.
enum DifficultyLevel {
  /// Entry-level difficulty with supportive prompts
  easy('Easy'),

  /// Mid-level difficulty with moderate challenge
  medium('Medium'),

  /// Senior-level difficulty with tough follow-ups
  hard('Hard');

  const DifficultyLevel(this.displayName);

  /// Human-readable display name for the difficulty level
  final String displayName;
}
