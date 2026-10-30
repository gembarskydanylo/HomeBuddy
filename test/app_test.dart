import 'package:drift/native.dart';
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          tasksProvider.overrideWith((ref) => Stream.value(const <Task>[])),
        ],
        child: const HomeBuddyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Твої справи'), findsOneWidget);
    expect(find.text('Поки що справ немає'), findsOneWidget);
    expect(find.text('Разом усе\nвстигнемо!'), findsOneWidget);
  });
}
