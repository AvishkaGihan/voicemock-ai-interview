import 'package:equatable/equatable.dart';

sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();

  @override
  String toString() => 'ConnectivityInitial';
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();

  @override
  String toString() => 'ConnectivityOnline';
}

class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();

  @override
  String toString() => 'ConnectivityOffline';
}
