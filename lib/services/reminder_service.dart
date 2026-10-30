import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/schedule/life_schedule.dart';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
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
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> schedule({
    required int taskId,
    required String title,
    required DateTime at,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
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

  Future<void> cancel(int taskId) => _plugin.cancel(id: taskId);
}
