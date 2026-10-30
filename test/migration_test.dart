import 'dart:io';

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
  test('on-disk upgrade and reopen preserve ids, status, reminders and photo paths', () async {
    final dir = await Directory.systemTemp.createTemp('homebuddy-migration-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/homebuddy.sqlite');
    var db = AppDatabase(
      executor: NativeDatabase(
        file,
        setup: (raw) {
          raw.execute(
            "CREATE TABLE tasks (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, category TEXT NOT NULL DEFAULT 'Дім', created_at INTEGER NOT NULL, due_at INTEGER, is_complete INTEGER NOT NULL DEFAULT 0)",
          );
          raw.execute(
            "INSERT INTO tasks (id,title,category,created_at,due_at,is_complete) VALUES (9,'Keep me','Інше',123,456,1)",
          );
          raw.execute('PRAGMA user_version=1');
        },
      ),
    );
    var task = (await db.select(db.tasks).get()).single;
    expect(task.id, 9);
    expect(task.category, 'Інше');
    expect(task.isComplete, isTrue);
    expect(task.dueAt, 456);
    final id = await db.addTask(
      title: 'Photo',
      category: 'Дім',
      photoPath: '/persistent/photo.jpg',
    );
    expect(id, greaterThan(9));
    await db.close();
    db = AppDatabase(executor: NativeDatabase(file));
    try {
      final tasks = await db.select(db.tasks).get();
      task = tasks.first;
      expect(task.id, 9);
      expect(task.isComplete, isTrue);
      expect(task.dueAt, 456);
      expect(tasks.last.photoPath, '/persistent/photo.jpg');
      expect(tasks, hasLength(2));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, 2);
    } finally {
      await db.close();
    }
  });
}
