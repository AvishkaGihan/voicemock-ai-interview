/// Interview feature - Presentation layer.
///
/// Contains:
/// - BLoCs / Cubits for state management
/// - Screens (Interview setup, active interview, summary)
/// - Widgets (recording indicator, transcript display, feedback card)
library;

export 'cubit/configuration_cubit.dart';
export 'cubit/configuration_state.dart';
export 'cubit/permission_cubit.dart';
export 'cubit/permission_state.dart';
export 'cubit/session_cubit.dart';
export 'cubit/session_state.dart';
export 'view/interview_page.dart';
export 'view/interview_view.dart';
export 'view/permission_rationale_page.dart';
export 'view/permission_rationale_view.dart';
export 'view/setup_page.dart';
export 'view/setup_view.dart';
export 'widgets/configuration_summary_card.dart';
export 'widgets/difficulty_selector.dart';
export 'widgets/permission_denied_banner.dart';
export 'widgets/question_count_selector.dart';
export 'widgets/role_selector.dart';
export 'widgets/session_error_dialog.dart';
export 'widgets/type_selector.dart';
