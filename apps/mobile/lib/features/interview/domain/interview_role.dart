/// Available interview roles for practice sessions.
///
/// These represent the job roles users can practice interviewing for.
/// Phase 1 MVP includes a focused set of common roles.
enum InterviewRole {
  /// Software Engineer role - technical and behavioral questions
  softwareEngineer('Software Engineer'),

  /// Product Manager role - product sense and leadership questions
  productManager('Product Manager'),

  /// Data Scientist role - analytical and technical questions
  dataScientist('Data Scientist'),

  /// General Business role - broad business and behavioral questions
  generalBusiness('General Business');

  const InterviewRole(this.displayName);

  /// Human-readable display name for the role
  final String displayName;
}
