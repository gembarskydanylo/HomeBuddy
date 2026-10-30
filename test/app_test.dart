import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_buddy/data/app_database.dart';
import 'package:home_buddy/features/home/home_page.dart';
import 'package:home_buddy/main.dart';

void main() {
  test(
    'tasks can be added, completed and removed from the local database',
    () async {
      final database = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(database.close);

      final id = await database.addTask(
        title: 'Полити квіти',
        category: 'Дім',
        dueAt: DateTime(2026, 11, 2, 18),
      );
      var tasks = await database.select(database.tasks).get();
      expect(tasks, hasLength(1));
      expect(tasks.single.id, id);
      expect(tasks.single.title, 'Полити квіти');

      await database.setComplete(tasks.single, true);
      tasks = await database.select(database.tasks).get();
      expect(tasks.single.isComplete, isTrue);

      await database.deleteTask(tasks.single);
      expect(await database.select(database.tasks).get(), isEmpty);
    },
  );

  testWidgets('home screen shows Cholera and the empty task state', (
    tester,
  ) async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          tasksProvider.overrideWith((ref) => Stream.value(const <Task>[])),
        ],
        child: const HomeBuddyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Твої справи'), findsOneWidget);
    expect(find.text('Поки що справ немає'), findsOneWidget);
    expect(find.text('Разом усе\nвстигнемо!'), findsOneWidget);
  });
  testWidgets('cold shortcut task entry saves and returns home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(executor: NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        tasksProvider.overrideWith((ref) => Stream.value(const <Task>[])),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(database.close);
    container.read(routerProvider).go('/tasks/new?mode=new');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HomeBuddyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextFormField), 'Repair the tap');
    await tester.ensureVisible(find.text('Зберегти справу'));
    await tester.tap(find.text('Зберегти справу'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      (await database.select(database.tasks).get()).single.title,
      'Repair the tap',
    );
    expect(find.text('Твої справи'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
