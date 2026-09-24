import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../../calendar_heatmap/data/repositories/calendar_repository.dart';
import '../../../focus_timer/domain/usecases/calculate_chunks_usecase.dart';
import '../../../focus_timer/presentation/reusable_widgets/phase_timeline_widget.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/data/repositories/goal_repository.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_event.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../data/services/backup_service.dart';
import '../../domain/entities/app_settings.dart';
import '../backup_files.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/duration_picker.dart';
import '../widgets/settings_toggle_switch.dart';

/// Settings save automatically; text fields are debounced.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  AppSettings? _draft;
  Timer? _debounce;
  late SettingsBloc _bloc;
  bool _isSendingTestEmail = false;
  bool _obscurePassword = true;
  bool? _notificationsAllowed;
  bool _backupBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have changed notification access in system settings.
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  T? _maybeRead<T>() {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshPermission() async {
    final repo = _maybeRead<NotificationRepository>();
    if (repo == null) return;
    final allowed = await repo.hasPermission();
    if (mounted) setState(() => _notificationsAllowed = allowed);
  }

  Future<void> _requestPermission() async {
    final repo = _maybeRead<NotificationRepository>();
    if (repo == null) return;
    final granted = await repo.requestPermission();
    if (!mounted) return;
    setState(() => _notificationsAllowed = granted);
    if (!granted) {
      _toast(
        'Notifications are blocked. Turn them on for Consistency in your system settings.',
      );
    }
  }

  void _toast(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  BackupService? _backupService() {
    final goals = _maybeRead<GoalRepository>();
    final calendar = _maybeRead<CalendarRepository>();
    if (goals == null || calendar == null) return null;
    return BackupService(
      goalRepository: goals,
      calendarRepository: calendar,
      notificationRepository: _maybeRead<NotificationRepository>(),
    );
  }

  Future<void> _exportBackup(Rect? origin) async {
    final service = _backupService();
    if (service == null) return;
    setState(() => _backupBusy = true);
    try {
      final json = await service.exportJson();
      final saved = await saveBackupFile(json, shareOrigin: origin);
      if (saved && mounted) _toast('Backup saved.');
    } catch (e) {
      if (mounted) _toast('Couldn’t export: $e', color: AppColors.danger);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importBackup() async {
    final service = _backupService();
    if (service == null) return;
    final String? text;
    try {
      text = await pickBackupFile();
    } catch (e) {
      _toast('Couldn’t open the file: $e', color: AppColors.danger);
      return;
    }
    if (text == null || !mounted) return;

    final List<(GoalModel, List<CalendarDayModel>)> items;
    try {
      items = service.parse(text);
    } on BackupFormatException catch (e) {
      _toast(e.message, color: AppColors.danger);
      return;
    }
    if (items.isEmpty) {
      _toast('No goals found in this backup.');
      return;
    }

    final days = items.fold<int>(0, (s, i) => s + i.$2.length);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Import ${items.length} ${items.length == 1 ? 'goal' : 'goals'}?',
        ),
        content: Text(
          'Includes $days days of history. Goals that already exist on this device are replaced by the backup version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _backupBusy = true);
    try {
      final count = await service.restore(items);
      if (!mounted) return;
      context.read<GoalBloc>().add(const LoadGoalsEvent());
      _toast('Imported $count ${count == 1 ? 'goal' : 'goals'}.');
    } catch (e) {
      if (mounted) _toast('Import failed: $e', color: AppColors.danger);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<SettingsBloc>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _persist();
    }
    super.dispose();
  }

  void _persist() {
    final draft = _draft;
    if (draft != null) _bloc.add(SettingsUpdated(draft));
  }

  void _update(AppSettings next, {bool debounce = false}) {
    setState(() => _draft = next);
    _debounce?.cancel();
    if (debounce) {
      _debounce = Timer(const Duration(milliseconds: 700), _persist);
    } else {
      _persist();
    }
  }

  Future<void> _sendTestEmail(AppSettings draft) async {
    final messenger = ScaffoldMessenger.of(context);
    void toast(String message, {Color? color}) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color),
        );
    }

    if (draft.accountabilityEmail.trim().isEmpty) {
      toast('Enter an accountability email first.');
      return;
    }
    if (draft.smtpPassword.trim().isEmpty) {
      toast('Enter your 16-character Gmail app password to authenticate.');
      return;
    }

    setState(() => _isSendingTestEmail = true);
    EmailService emailService;
    try {
      emailService = context.read<EmailService>();
    } catch (_) {
      emailService = EmailServiceImpl();
    }
    final success = await emailService.sendTestEmail(settings: draft);
    if (!mounted) return;
    setState(() => _isSendingTestEmail = false);
    toast(
      success
          ? 'Test email sent. Check your inbox.'
          : 'Couldn’t send. Check the address and app password.',
      color: success ? null : AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show a back button when pushed as its own route (not as a tab).
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final body = BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoaded && !(_debounce?.isActive ?? false)) {
          _draft = state.settings;
        }
        if (state is SettingsError && _draft == null) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }
        final draft =
            _draft ?? (state is SettingsLoaded ? state.settings : null);
        // Saving emits a transient loading state; keep showing the draft.
        if (draft == null) {
          return state is SettingsInitial
              ? _buildContent(context, AppSettings.defaults, canPop)
              : const Center(child: CircularProgressIndicator());
        }
        return _buildContent(context, draft, canPop);
      },
    );

    if (!canPop) {
      return Scaffold(backgroundColor: Colors.transparent, body: body);
    }
    return Scaffold(backgroundColor: AppColors.background, body: body);
  }

  Widget _buildContent(BuildContext context, AppSettings draft, bool canPop) {
    final theme = Theme.of(context).textTheme;
    final preview = CalculateChunksUseCase()(
      totalTargetMinutes: 60,
      settings: draft,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = math.max(20.0, (constraints.maxWidth - 640) / 2);
        final bottom = MediaQuery.paddingOf(context).bottom + 24;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 8),
                sliver: SliverToBoxAdapter(
                  child: PageHeader(
                    title: 'Settings',
                    subtitle: 'Changes save automatically',
                    leading: canPop
                        ? AppIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back',
                            onTap: () => Navigator.of(context).maybePop(),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 12, gutter, bottom),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: 8),
                  const _SectionHeader(
                    title: 'Session setup',
                    subtitle: 'How long sessions are split into focus blocks.',
                  ),
                  _Group(
                    children: [
                      DurationPicker(
                        label: 'Focus block',
                        icon: Icons.timer_outlined,
                        valueMinutes: draft.focusDurationMinutes,
                        minMinutes: 5,
                        maxMinutes: 120,
                        step: 5,
                        onChanged: (v) =>
                            _update(draft.copyWith(focusDurationMinutes: v)),
                      ),
                      DurationPicker(
                        label: 'Break',
                        description: '0 = no breaks',
                        icon: Icons.coffee_outlined,
                        valueMinutes: draft.breakDurationMinutes,
                        minMinutes: 0,
                        maxMinutes: 60,
                        onChanged: (v) =>
                            _update(draft.copyWith(breakDurationMinutes: v)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('A 60-minute session', style: theme.bodySmall),
                            const SizedBox(height: 10),
                            PhaseTimelineWidget(
                              phases: preview.phases,
                              focusColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'Feedback'),
                  _Group(
                    children: [
                      SettingsToggleSwitch(
                        label: 'Sound & haptics',
                        description: 'A subtle cue when phases switch.',
                        icon: Icons.volume_up_outlined,
                        value: draft.soundEnabled,
                        onChanged: (v) =>
                            _update(draft.copyWith(soundEnabled: v)),
                      ),
                      SettingsToggleSwitch(
                        label: 'Phase notifications',
                        description: 'Notify when a focus block or break ends.',
                        icon: Icons.notifications_none_rounded,
                        value: draft.notificationsEnabled,
                        onChanged: (v) {
                          _update(draft.copyWith(notificationsEnabled: v));
                          if (v && _notificationsAllowed != true) {
                            _requestPermission();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'Reminders'),
                  _Group(
                    children: [
                      if (_notificationsAllowed == false)
                        _ActionRow(
                          icon: Icons.notifications_off_outlined,
                          label: 'Notifications are off',
                          description:
                              'Reminders can’t reach you until you allow them.',
                          actionLabel: 'Allow',
                          onTap: _requestPermission,
                        ),
                      SettingsToggleSwitch(
                        label: 'Countdown reminders',
                        description:
                            'Extra nudges 30, 20, 10, 5 and 1 minute before each reminder, even when the app is closed.',
                        icon: Icons.alarm_rounded,
                        value: draft.escalationRemindersEnabled,
                        onChanged: (v) => _update(
                          draft.copyWith(escalationRemindersEnabled: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(
                    title: 'Accountability',
                    subtitle:
                        'Get an encouraging check-in email when daily targets are missed.',
                  ),
                  _Group(
                    children: [
                      SettingsToggleSwitch(
                        label: 'Email check-in',
                        description: 'Evening email if targets are unmet.',
                        icon: Icons.mail_outline_rounded,
                        value: draft.accountabilityEmailEnabled,
                        onChanged: (v) => _update(
                          draft.copyWith(accountabilityEmailEnabled: v),
                        ),
                      ),
                      AnimatedSize(
                        duration: AppMotion.medium,
                        curve: AppMotion.standard,
                        alignment: Alignment.topCenter,
                        child: !draft.accountabilityEmailEnabled
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      initialValue: draft.accountabilityEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Accountability email',
                                        hintText: 'you@gmail.com',
                                        prefixIcon: Icon(
                                          Icons.alternate_email_rounded,
                                        ),
                                      ),
                                      onChanged: (v) => _update(
                                        draft.copyWith(
                                          accountabilityEmail: v.trim(),
                                        ),
                                        debounce: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      initialValue: draft.smtpPassword,
                                      obscureText: _obscurePassword,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Gmail app password',
                                        helperText:
                                            'Google Account › Security › App passwords',
                                        prefixIcon: const Icon(
                                          Icons.key_rounded,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      ),
                                      onChanged: (v) => _update(
                                        draft.copyWith(smtpPassword: v.trim()),
                                        debounce: true,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _isSendingTestEmail
                                          ? null
                                          : () => _sendTestEmail(draft),
                                      icon: _isSendingTestEmail
                                          ? const SizedBox.square(
                                              dimension: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.send_rounded,
                                              size: 18,
                                            ),
                                      label: Text(
                                        _isSendingTestEmail
                                            ? 'Sending…'
                                            : 'Send test email',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(
                    title: 'Data',
                    subtitle:
                        'Everything is stored on this device. Export a backup to keep it safe or move to another device.',
                  ),
                  _Group(
                    children: [
                      Builder(
                        builder: (rowContext) => _ActionRow(
                          icon: Icons.ios_share_rounded,
                          label: 'Export backup',
                          description: 'All goals and history as a JSON file',
                          busy: _backupBusy,
                          onTap: () {
                            final box =
                                rowContext.findRenderObject() as RenderBox?;
                            _exportBackup(
                              box == null
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size,
                            );
                          },
                        ),
                      ),
                      _ActionRow(
                        icon: Icons.restore_rounded,
                        label: 'Import backup',
                        description: 'Restore goals from a backup file',
                        busy: _backupBusy,
                        onTap: _importBackup,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'About'),
                  _Group(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const SettingsIcon(
                              icon: Icons.lock_outline_rounded,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stored on this device',
                                    style: theme.titleSmall,
                                  ),
                                  Text(
                                    'Goals and history never leave your device.',
                                    style: theme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const SettingsIcon(
                              icon: Icons.info_outline_rounded,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Consistency Tracker',
                                style: theme.titleSmall,
                              ),
                            ),
                            Text('v1.0.0', style: theme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tappable settings row with an optional trailing action label.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.actionLabel,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final String? actionLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return InkWell(
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SettingsIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.titleSmall),
                  const SizedBox(height: 2),
                  Text(description, style: theme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (busy)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (actionLabel != null)
              Text(
                actionLabel!,
                style: theme.labelMedium?.copyWith(color: AppColors.primary),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: theme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Inset-grouped card with hairline dividers.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: 66),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
