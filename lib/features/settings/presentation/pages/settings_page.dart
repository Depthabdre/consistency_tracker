import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/duration_picker.dart';
import '../widgets/settings_toggle_switch.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _draft;
  bool _initialized = false;

  void _syncDraftIfNeeded(AppSettings settings) {
    if (_initialized) {
      return;
    }
    _draft = settings;
    _initialized = true;
  }

  void _saveSettings(BuildContext context) {
    context.read<SettingsBloc>().add(SettingsUpdated(_draft));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully.'),
        backgroundColor: AppTheme.accentCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (BuildContext context, SettingsState state) {
              if (state is SettingsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentCyan),
                );
              }

              if (state is SettingsError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Color(0xFFF43F5E)),
                  ),
                );
              }

              final AppSettings loaded = state is SettingsLoaded
                  ? state.settings
                  : AppSettings.defaults;
              _syncDraftIfNeeded(loaded);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2D32),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderOutline, width: 1.2),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Session setup',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configure your focus and break durations.\n'
                              'The timer chunks your total target time using these values.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 22),
                            DurationPicker(
                              label: 'Focus duration',
                              valueMinutes: _draft.focusDurationMinutes,
                              minMinutes: 5,
                              maxMinutes: 120,
                              onChanged: (int value) {
                                setState(() {
                                  _draft = _draft.copyWith(focusDurationMinutes: value);
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            DurationPicker(
                              label: 'Break duration',
                              valueMinutes: _draft.breakDurationMinutes,
                              minMinutes: 0,
                              maxMinutes: 60,
                              onChanged: (int value) {
                                setState(() {
                                  _draft = _draft.copyWith(breakDurationMinutes: value);
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            SettingsToggleSwitch(
                              label: 'Enable sound',
                              description: 'Play a subtle chime when phases switch.',
                              value: _draft.soundEnabled,
                              onChanged: (bool enabled) {
                                setState(() {
                                  _draft = _draft.copyWith(soundEnabled: enabled);
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            SettingsToggleSwitch(
                              label: 'Enable notifications',
                              description: 'Show notifications on phase transitions.',
                              value: _draft.notificationsEnabled,
                              onChanged: (bool enabled) {
                                setState(() {
                                  _draft = _draft.copyWith(
                                    notificationsEnabled: enabled,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () => _saveSettings(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2FB7FF),
                                  foregroundColor: const Color(0xFF0A1A27),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save changes',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
