import '../../features/notifications/data/repositories/notification_repository.dart';

abstract class NotificationService {
  Future<void> showPhaseNotification({
    required String title,
    required String body,
    required bool enabled,
    Function()? onUserInteraction,
  });
}

class NotificationServiceImpl implements NotificationService {
  final NotificationRepository notificationRepository;

  NotificationServiceImpl({required this.notificationRepository});

  @override
  Future<void> showPhaseNotification({
    required String title,
    required String body,
    required bool enabled,
    Function()? onUserInteraction,
  }) async {
    if (!enabled) return;
    try {
      await notificationRepository.showImmediateNotification(
        title: title,
        body: body,
      );
    } catch (_) {
      // Fallback gracefully if notifications are denied or unavailable
    }
  }
}
