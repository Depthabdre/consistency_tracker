import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  SettingsBloc({required this.repository}) : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<SettingsUpdated>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    final result = await repository.getSettings();
    result.fold(
      onSuccess: (settings) => emit(SettingsLoaded(settings)),
      onFailure: (failure) => emit(SettingsError(failure.message)),
    );
  }

  Future<void> _onUpdateSettings(
    SettingsUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    final saveResult = await repository.saveSettings(event.settings);
    saveResult.fold(
      onSuccess: (_) => emit(SettingsLoaded(event.settings)),
      onFailure: (failure) => emit(SettingsError(failure.message)),
    );
  }
}
