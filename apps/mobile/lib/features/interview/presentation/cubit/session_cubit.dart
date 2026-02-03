import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:voicemock/features/interview/domain/domain.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_state.dart';

/// Cubit managing session lifecycle.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required SessionRepository repository})
    : _repository = repository,
      super(SessionInitial());
  final SessionRepository _repository;

  /// Starts a new interview session with given configuration.
  Future<void> startSession(InterviewConfig config) async {
    emit(SessionLoading());

    final result = await _repository.startSession(config);

    result.fold(
      (failure) => emit(SessionFailure(failure: failure)),
      (session) => emit(SessionSuccess(session: session)),
    );
  }
}
