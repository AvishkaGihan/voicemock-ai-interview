import 'package:equatable/equatable.dart';
import 'package:voicemock/features/interview/domain/domain.dart';

/// State for interview configuration.
///
/// Holds the current configuration selections and loading status.
class ConfigurationState extends Equatable {
  const ConfigurationState({
    required this.config,
    this.isLoading = false,
    this.isRestoredFromPrefs = false,
  });

  /// Creates initial state with default configuration.
  factory ConfigurationState.initial() {
    return ConfigurationState(
      config: InterviewConfig.defaults(),
    );
  }

  /// The current interview configuration
  final InterviewConfig config;

  /// Whether the state is being loaded from preferences
  final bool isLoading;

  /// Whether the configuration was restored from shared preferences
  final bool isRestoredFromPrefs;

  /// Creates a copy with the specified changes.
  ConfigurationState copyWith({
    InterviewConfig? config,
    bool? isLoading,
    bool? isRestoredFromPrefs,
  }) {
    return ConfigurationState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      isRestoredFromPrefs: isRestoredFromPrefs ?? this.isRestoredFromPrefs,
    );
  }

  @override
  List<Object?> get props => [config, isLoading, isRestoredFromPrefs];
}
