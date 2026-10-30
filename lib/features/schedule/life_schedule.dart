import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Calendar-based work shifts, including shifts that cross midnight.
class LifeSchedule {
  LifeSchedule({
    this.shift = false,
    this.weekdays = const [1, 2, 3, 4, 5],
    this.workStart = 540,
    this.workEnd = 1020,
    this.commute = 30,
    this.rest = 60,
    this.sleepStart = 1380,
    this.sleepEnd = 420,
    this.allowedStart = 480,
    this.allowedEnd = 1320,
    this.onDays = 2,
    this.offDays = 2,
    DateTime? anchor,
  }) : anchor = anchor ?? DateTime(2026, 1, 1);
  bool shift;
  List<int> weekdays;
  int workStart,
      workEnd,
      commute,
      rest,
      sleepStart,
      sleepEnd,
      allowedStart,
      allowedEnd,
      onDays,
      offDays;
  DateTime anchor;
  bool workDay(DateTime d) {
    if (!shift) return weekdays.contains(d.weekday);
    final delta = DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(anchor.year, anchor.month, anchor.day)).inDays;
    return delta % (onDays + offDays) < onDays;
  }

  static bool inWindow(int minute, int start, int end) =>
      start == end ||
      (start < end
          ? minute >= start && minute < end
          : minute >= start || minute < end);
  bool permits(DateTime d) {
    final minute = d.hour * 60 + d.minute;
    if (!inWindow(minute, allowedStart, allowedEnd) ||
        inWindow(minute, sleepStart, sleepEnd)) {
      return false;
    }
    for (final offset in [0, -1]) {
      final day = DateTime(d.year, d.month, d.day + offset);
      if (!workDay(day)) continue;
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        workStart ~/ 60,
        workStart % 60,
      );
      final end = DateTime(
        day.year,
        day.month,
        day.day + (workEnd <= workStart ? 1 : 0),
        workEnd ~/ 60,
        workEnd % 60,
      ).add(Duration(minutes: commute + rest));
      if (!d.isBefore(start) && d.isBefore(end)) return false;
    }
    return true;
  }

  DateTime nextAllowed(DateTime requested) {
    var d = requested;
    for (var i = 0; i < 60 * 24 * 35; i++) {
      if (permits(d)) return d;
      d = d.add(const Duration(minutes: 1));
    }
    throw StateError('У графіку немає доступного часу протягом 35 днів.');
  }

  Map<String, dynamic> toJson() => {
    'shift': shift,
    'weekdays': weekdays,
    'workStart': workStart,
    'workEnd': workEnd,
    'commute': commute,
    'rest': rest,
    'sleepStart': sleepStart,
    'sleepEnd': sleepEnd,
    'allowedStart': allowedStart,
    'allowedEnd': allowedEnd,
    'onDays': onDays,
    'offDays': offDays,
    'anchor': anchor.toIso8601String(),
  };
  factory LifeSchedule.fromJson(Map<String, dynamic> j) => LifeSchedule(
    shift: j['shift'],
    weekdays: List<int>.from(j['weekdays']),
    workStart: j['workStart'],
    workEnd: j['workEnd'],
    commute: j['commute'],
    rest: j['rest'],
    sleepStart: j['sleepStart'],
    sleepEnd: j['sleepEnd'],
    allowedStart: j['allowedStart'],
    allowedEnd: j['allowedEnd'],
    onDays: j['onDays'],
    offDays: j['offDays'],
    anchor: DateTime.parse(j['anchor']),
  );
  static Future<LifeSchedule> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('lifeSchedule');
    return s == null ? LifeSchedule() : LifeSchedule.fromJson(jsonDecode(s));
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lifeSchedule', jsonEncode(toJson()));
  }
}
