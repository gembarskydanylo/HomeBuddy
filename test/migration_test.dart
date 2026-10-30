import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_buddy/data/app_database.dart';

void main() {
  test('v1 database upgrades without losing existing tasks', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        db.execute(
          "CREATE TABLE tasks (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, category TEXT NOT NULL DEFAULT 'Дім', created_at INTEGER NOT NULL, due_at INTEGER, is_complete INTEGER NOT NULL DEFAULT 0);",
        );
        db.execute(
          "INSERT INTO tasks (title, created_at) VALUES ('Existing task', 1)",
        );
        db.execute('PRAGMA user_version = 1');
      },
    );
    final db = AppDatabase(executor: executor);
    addTearDown(db.close);
    final old = (await db.select(db.tasks).get()).single;
    expect(old.title, 'Existing task');
    expect(old.photoPath, isNull);
    await db.addTask(
      title: 'Photo task',
      category: 'Дім',
      photoPath: '/local/photo.jpg',
    );
    expect(
      (await db.select(db.tasks).get()).last.photoPath,
      '/local/photo.jpg',
    );
  });
}
