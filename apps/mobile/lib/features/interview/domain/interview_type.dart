/// Types of interview practice available.
///
/// Determines the style and focus of questions during the session.
enum InterviewType {
  /// Behavioral interview - "Tell me about a time..." style questions
  behavioral('Behavioral'),

  /// Technical interview - Role-specific technical questions
  technical('Technical');

  const InterviewType(this.displayName);

  /// Human-readable display name for the interview type
  final String displayName;
}
