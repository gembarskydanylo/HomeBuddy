import 'package:flutter_test/flutter_test.dart';
import 'package:home_buddy/features/schedule/life_schedule.dart';

void main() {
  test('weekday reminders move past work, commute and recovery', () {
    final s = LifeSchedule();
    expect(
      s.nextAllowed(DateTime(2026, 11, 2, 10)),
      DateTime(2026, 11, 2, 18, 30),
    );
  });
  test('weekend remains available; sleep moves to morning', () {
    final s = LifeSchedule();
    expect(s.nextAllowed(DateTime(2026, 11, 1, 10)), DateTime(2026, 11, 1, 10));
    expect(s.nextAllowed(DateTime(2026, 11, 1, 1)), DateTime(2026, 11, 1, 8));
  });
  test('night shift blocks next morning including commute', () {
    final s = LifeSchedule(
      shift: true,
      anchor: DateTime(2026, 11, 1),
      workStart: 1320,
      workEnd: 360,
      sleepStart: 480,
      sleepEnd: 960,
      allowedStart: 0,
      allowedEnd: 0,
    );
    expect(s.permits(DateTime(2026, 11, 2, 6, 30)), false);
    expect(s.permits(DateTime(2026, 11, 2, 17)), true);
  });
  test('shift cycle and settings roundtrip', () {
    final s = LifeSchedule(shift: true, anchor: DateTime(2026, 11, 1));
    expect(s.workDay(DateTime(2026, 11, 3)), false);
    expect(LifeSchedule.fromJson(s.toJson()).toJson(), s.toJson());
  });
}
