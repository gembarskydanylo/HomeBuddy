import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get category => text().withDefault(const Constant('Дім'))();
  IntColumn get createdAt => integer()();
  IntColumn get dueAt => integer().nullable()();
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor})
    : super(executor ?? driftDatabase(name: 'home_buddy'));

  @override
  int get schemaVersion => 1;

  Stream<List<Task>> watchTasks() =>
      (select(tasks)..orderBy([
            (task) => OrderingTerm(expression: task.isComplete),
            (task) => OrderingTerm(expression: task.dueAt),
            (task) => OrderingTerm(expression: task.createdAt),
          ]))
          .watch();

  Future<int> addTask({
    required String title,
    required String category,
    DateTime? dueAt,
  }) {
    return into(tasks).insert(
      TasksCompanion.insert(
        title: title.trim(),
        category: Value(category),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        dueAt: Value(dueAt?.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setComplete(Task task, bool isComplete) =>
      (update(tasks)..where((row) => row.id.equals(task.id))).write(
        TasksCompanion(isComplete: Value(isComplete)),
      );

  Future<int> deleteTask(Task task) =>
      (delete(tasks)..where((row) => row.id.equals(task.id))).go();
}
