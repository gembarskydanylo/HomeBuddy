import 'dart:io';

import '../data/app_database.dart';
import 'reminder_service.dart';

/// Cancel first: a failed OS cancellation must not leave a completed/deleted
/// task with a live reminder. Database failure after cancellation is safe.
class TaskActions {
  TaskActions(this.database, this.reminders);
  final AppDatabase database;
  final TaskReminders reminders;

  Future<void> _tail = Future.value();
  Future<void> _run(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<void> setComplete(Task task, bool complete) => _run(() async {
    final existing = await (database.select(
      database.tasks,
    )..where((row) => row.id.equals(task.id))).getSingleOrNull();
    if (existing == null) return;
    if (complete) await reminders.cancel(task.id);
    await database.setComplete(task, complete);
    if (!complete && task.dueAt != null) {
      await reminders.schedule(
        taskId: task.id,
        title: task.title,
        at: DateTime.fromMillisecondsSinceEpoch(task.dueAt!),
      );
    }
  });

  Future<void> delete(Task task) => _run(() async {
    await reminders.cancel(task.id);
    await database.deleteTask(task);
    if (task.photoPath != null) {
      try {
        final photo = File(task.photoPath!);
        if (await photo.exists()) await photo.delete();
      } on FileSystemException {
        /* A stale attachment must not restore a task. */
      }
    }
  });
}
