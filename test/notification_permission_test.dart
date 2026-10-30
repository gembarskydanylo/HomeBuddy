import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_buddy/services/reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'denied notification permission is reported without scheduling',
    () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return false;
          });
      expect(await ReminderService.instance.requestPermission(), isFalse);
      await expectLater(
        ReminderService.instance.schedule(
          taskId: 1,
          title: 'Keep local',
          at: DateTime.now().add(const Duration(days: 1)),
        ),
        throwsStateError,
      );
      expect(calls, isNot(contains('zonedSchedule')));
    },
  );
  test('disabled reminder channel is detected even when app notifications are enabled', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getNotificationChannels') {
            return [
              {
                'id': 'home_buddy_reminders',
                'name': 'Нагадування',
                'importance': 0,
                'playSound': false,
                'enableVibration': false,
                'enableLights': false,
                'showBadge': true,
                'bypassDnd': false,
                'ledColor': 0,
                'audioAttributesUsage': 5,
              },
            ];
          }
          return true;
        });
    expect(await ReminderService.instance.requestPermission(), isFalse);
  });
}
