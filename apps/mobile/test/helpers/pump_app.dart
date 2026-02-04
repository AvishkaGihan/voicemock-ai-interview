import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voicemock/core/connectivity/connectivity.dart';
import 'package:voicemock/core/permissions/permission_service.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/configuration_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/permission_state.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_cubit.dart';
import 'package:voicemock/features/interview/presentation/cubit/session_state.dart';
import 'package:voicemock/l10n/l10n.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

class MockSessionCubit extends MockCubit<SessionState>
    implements SessionCubit {}

class MockConfigurationCubit extends MockCubit<ConfigurationState>
    implements ConfigurationCubit {}

class MockPermissionCubit extends MockCubit<PermissionState>
    implements PermissionCubit {}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ConnectivityCubit? connectivityCubit,
    SessionCubit? sessionCubit,
    ConfigurationCubit? configurationCubit,
    PermissionCubit? permissionCubit,
  }) {
    // Set up default mocks if not provided
    final mockConnectivityCubit = connectivityCubit ?? MockConnectivityCubit();
    final mockSessionCubit = sessionCubit ?? MockSessionCubit();
    final mockConfigurationCubit =
        configurationCubit ?? MockConfigurationCubit();
    final mockPermissionCubit = permissionCubit ?? MockPermissionCubit();

    // Set default states
    if (connectivityCubit == null) {
      when(
        () => mockConnectivityCubit.state,
      ).thenReturn(const ConnectivityOnline());
      when(mockConnectivityCubit.checkConnectivity).thenAnswer((_) async {});
    }

    if (sessionCubit == null) {
      when(() => mockSessionCubit.state).thenReturn(SessionInitial());
    }

    if (configurationCubit == null) {
      when(() => mockConfigurationCubit.state).thenReturn(
        ConfigurationState.initial(),
      );
    }

    if (permissionCubit == null) {
      when(() => mockPermissionCubit.state).thenReturn(
        PermissionState.initial().copyWith(
          status: MicrophonePermissionStatus.granted,
          hasChecked: true,
        ),
      );
    }

    return pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityCubit>.value(
            value: mockConnectivityCubit,
          ),
          BlocProvider<SessionCubit>.value(
            value: mockSessionCubit,
          ),
          BlocProvider<ConfigurationCubit>.value(
            value: mockConfigurationCubit,
          ),
          BlocProvider<PermissionCubit>.value(
            value: mockPermissionCubit,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget,
        ),
      ),
    );
  }
}
