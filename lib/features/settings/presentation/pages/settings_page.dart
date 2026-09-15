import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/email_service.dart';
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
  bool _isSendingTestEmail = false;
  bool _obscurePassword = true;

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
                        border: Border.all(
                          color: AppTheme.borderOutline,
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Session setup',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configure your focus and break durations.\n'
                              'The timer chunks your total target time using these values.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
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
                                  _draft = _draft.copyWith(
                                    focusDurationMinutes: value,
                                  );
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
                                  _draft = _draft.copyWith(
                                    breakDurationMinutes: value,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            SettingsToggleSwitch(
                              label: 'Enable sound',
                              description:
                                  'Play a subtle chime when phases switch.',
                              value: _draft.soundEnabled,
                              onChanged: (bool enabled) {
                                setState(() {
                                  _draft = _draft.copyWith(
                                    soundEnabled: enabled,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            SettingsToggleSwitch(
                              label: 'Enable notifications',
                              description:
                                  'Show notifications on phase transitions.',
                              value: _draft.notificationsEnabled,
                              onChanged: (bool enabled) {
                                setState(() {
                                  _draft = _draft.copyWith(
                                    notificationsEnabled: enabled,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            SettingsToggleSwitch(
                              label: 'Smart escalation reminders',
                              description:
                                  'Sends countdown reminders (30m, 20m, 10m, 5m, 1m) even when the app is closed.',
                              value: _draft.escalationRemindersEnabled,
                              onChanged: (bool enabled) {
                                setState(() {
                                  _draft = _draft.copyWith(
                                    escalationRemindersEnabled: enabled,
                                  );
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: AppTheme.borderOutline),
                            const SizedBox(height: 16),
                            Text(
                              'Email accountability',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Optionally receive an encouraging check-in if daily focus targets are missed.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 14),
                            SettingsToggleSwitch(
                              label: 'Enable email check-in',
                              description:
                                  'Sends evening notification if targets are unmet.',
                              value: _draft.accountabilityEmailEnabled,
                              onChanged: (bool enabled) {
                                setState(() {
                                  _draft = _draft.copyWith(
                                    accountabilityEmailEnabled: enabled,
                                  );
                                });
                              },
                            ),
                            if (_draft.accountabilityEmailEnabled) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                initialValue: _draft.accountabilityEmail,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  labelText:
                                      'Accountability email (e.g. user@gmail.com)',
                                  labelStyle: const TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.backgroundStart,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderOutline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.accentCyan,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  _draft = _draft.copyWith(
                                    accountabilityEmail: value.trim(),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _draft.smtpPassword,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  labelText:
                                      'Gmail App Password (16 characters)',
                                  helperText:
                                      'Generate at: Google Account > Security > App Passwords',
                                  helperStyle: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: AppTheme.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  labelStyle: const TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.backgroundStart,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderOutline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.accentCyan,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  _draft = _draft.copyWith(
                                    smtpPassword: value.trim(),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: _isSendingTestEmail
                                      ? null
                                      : () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final email = _draft
                                              .accountabilityEmail
                                              .trim();
                                          if (email.isEmpty) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter an accountability email address first.',
                                                ),
                                                backgroundColor:
                                                    AppTheme.errorRed,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            return;
                                          }
                                          if (_draft.smtpPassword
                                              .trim()
                                              .isEmpty) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter your 16-character Gmail App Password to authenticate.',
                                                ),
                                                backgroundColor:
                                                    AppTheme.errorRed,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                            return;
                                          }

                                          setState(
                                            () => _isSendingTestEmail = true,
                                          );
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Sending test email...',
                                              ),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );

                                          EmailService emailService;
                                          try {
                                            emailService = context
                                                .read<EmailService>();
                                          } catch (_) {
                                            emailService = EmailServiceImpl();
                                          }

                                          final success = await emailService
                                              .sendTestEmail(settings: _draft);
                                          if (!mounted) return;
                                          setState(
                                            () => _isSendingTestEmail = false,
                                          );

                                          if (success) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Test email sent successfully! Please check your inbox.',
                                                ),
                                                backgroundColor:
                                                    AppTheme.successGreen,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          } else {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not send test email. Please verify recipient and SMTP / Gmail app password settings.',
                                                ),
                                                backgroundColor:
                                                    AppTheme.errorRed,
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        },
                                  icon: _isSendingTestEmail
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.accentCyan,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          size: 16,
                                        ),
                                  label: Text(
                                    _isSendingTestEmail
                                        ? 'Sending...'
                                        : 'Send test check-in email',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accentCyan,
                                    side: const BorderSide(
                                      color: AppTheme.borderOutline,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () => _saveSettings(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.accentCyan,
                                  foregroundColor: Colors.black,
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
