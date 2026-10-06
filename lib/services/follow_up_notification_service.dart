import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract final class FollowUpNotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> initialize() async {
    if (_ready) return;
    tz.initializeTimeZones();
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> schedule({
    required int reportId,
    required String crop,
    required String disease,
    required DateTime dueAt,
  }) async {
    await initialize();
    final scheduled = tz.TZDateTime.from(
      DateTime(dueAt.year, dueAt.month, dueAt.day, 9),
      tz.local,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _notifications.zonedSchedule(
      id: reportId,
      title: 'Crop follow-up due',
      body: 'Check your $crop for $disease today.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'crop_follow_ups',
          'Crop follow-ups',
          channelDescription: 'Reminders to review saved crop scans.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}