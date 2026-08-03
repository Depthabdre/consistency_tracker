import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class SettingsUpdated extends SettingsEvent {
  final AppSettings settings;

  const SettingsUpdated(this.settings);

  @override
  List<Object?> get props => [settings];
}
