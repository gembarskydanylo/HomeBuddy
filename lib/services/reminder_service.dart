import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/schedule/life_schedule.dart';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract interface class TaskReminders {
  Future<void> cancel(int taskId);
  Future<void> schedule({
    required int taskId,
    required String title,
    required DateTime at,
  });
}

class ReminderService implements TaskReminders {
  ReminderService._();

  static final instance = ReminderService._();
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.requestNotificationsPermission() != true) return false;
    return notificationsEnabled();
  }

  Future<bool> notificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null || await android.areNotificationsEnabled() != true) {
      return false;
    }
    final channels = await android.getNotificationChannels();
    return !(channels ?? []).any(
      (c) => c.id == 'home_buddy_reminders' && c.importance == Importance.none,
    );
  }

  @override
  Future<void> schedule({
    required int taskId,
    required String title,
    required DateTime at,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    if (!await notificationsEnabled()) {
      throw StateError(
        'Сповіщення HomeBuddy або канал нагадувань вимкнено в Android.',
      );
    }
    final schedule = await LifeSchedule.load();
    at = schedule.nextAllowed(at);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'home_buddy_reminders',
        'Нагадування про справи',
        channelDescription: 'Локальні нагадування HomeBuddy',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      id: taskId,
      title: 'Час для справи 🏡',
      body: title,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<Set<int>> pendingIds() async =>
      (await _plugin.pendingNotificationRequests()).map((n) => n.id).toSet();

  @override
  Future<void> cancel(int taskId) => _plugin.cancel(id: taskId);
}
