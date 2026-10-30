import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_buddy/data/app_database.dart';
import 'package:home_buddy/services/reminder_service.dart';
import 'package:home_buddy/services/task_actions.dart';

class FakeReminders implements TaskReminders {
  final pending = <int>{};
  bool failCancel = false;
  Completer<void>? scheduleGate;
  @override
  Future<void> cancel(int id) async {
    if (failCancel) throw StateError('OS failure');
    pending.remove(id);
  }

  @override
  Future<void> schedule({
    required int taskId,
    required String title,
    required DateTime at,
  }) async {
    if (scheduleGate != null) await scheduleGate!.future;
    pending.add(taskId);
  }
}

void main() {
  test('completed/deleted tasks lose reminders; failed cancellation keeps task active', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final reminders = FakeReminders();
    final actions = TaskActions(db, reminders);
    final id = await db.addTask(
      title: 'Repair',
      category: 'Дім',
      dueAt: DateTime.now().add(const Duration(days: 1)),
    );
    Task task = (await db.select(db.tasks).get()).single;
    reminders.pending.add(id);
    reminders.failCancel = true;
    await expectLater(actions.setComplete(task, true), throwsStateError);
    expect((await db.select(db.tasks).get()).single.isComplete, isFalse);
    await expectLater(actions.delete(task), throwsStateError);
    expect(await db.select(db.tasks).get(), hasLength(1));
    reminders.failCancel = false;
    await actions.setComplete(task, true);
    expect(reminders.pending, isEmpty);
    task = (await db.select(db.tasks).get()).single;
    expect(task.isComplete, isTrue);
    await actions.setComplete(task, false);
    expect(reminders.pending, {id});
    await actions.delete(task);
    expect(reminders.pending, isEmpty);
    expect(await db.select(db.tasks).get(), isEmpty);
  });
  test(
    'overlapping restore/complete and stale taps cannot resurrect reminders',
    () async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      await db.addTask(
        title: 'Race',
        category: 'Дім',
        dueAt: DateTime.now().add(const Duration(days: 1)),
      );
      final task = (await db.select(db.tasks).get()).single;
      final reminders = FakeReminders()..scheduleGate = Completer<void>();
      final actions = TaskActions(db, reminders);
      final restoring = actions.setComplete(task, false);
      final completing = actions.setComplete(task, true);
      reminders.scheduleGate!.complete();
      await Future.wait([restoring, completing]);
      expect(reminders.pending, isEmpty);
      expect((await db.select(db.tasks).get()).single.isComplete, isTrue);
      await actions.delete(task);
      await actions.setComplete(task, false);
      expect(reminders.pending, isEmpty);
      expect(await db.select(db.tasks).get(), isEmpty);
    },
  );
}
