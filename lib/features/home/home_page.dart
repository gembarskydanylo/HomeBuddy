import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../main.dart';
import '../../services/reminder_service.dart';
import '../character/cholera_character.dart';

final tasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(databaseProvider).watchTasks();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOME BUDDY',
                              style: TextStyle(
                                color: Color(0xFF688274),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Привіт, друже',
                              style: TextStyle(
                                fontSize: 28,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF273C33),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6EDE5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Color(0xFF527461),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push('/schedule'),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Мій розклад'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _BuddyCard(),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Твої справи',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF273C33),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/tasks/new'),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: const Text('Додати'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  tasks.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) =>
                        Text('Не вдалося завантажити справи: $error'),
                    data: (items) => items.isEmpty
                        ? const _EmptyTasks()
                        : Column(
                            children: items
                                .map((task) => _TaskTile(task: task))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/new'),
        backgroundColor: const Color(0xFF537A67),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Нова справа'),
      ),
    );
  }
}

class _BuddyCard extends StatelessWidget {
  const _BuddyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCE8DB),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Твій домашній помічник',
                  style: TextStyle(
                    color: Color(0xFF527461),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Разом усе\nвстигнемо!',
                  style: TextStyle(
                    color: Color(0xFF273C33),
                    fontSize: 24,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Крок за кроком — і вдома лад.',
                  style: TextStyle(color: Color(0xFF527461), fontSize: 12),
                ),
              ],
            ),
          ),
          const CholeraCharacter(size: 128),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Column(
      children: [
        Icon(Icons.checklist_rounded, size: 36, color: Color(0xFF8CA393)),
        SizedBox(height: 8),
        Text(
          'Поки що справ немає',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'Додай першу — Холера підтримає!',
          style: TextStyle(color: Color(0xFF78877E), fontSize: 12),
        ),
      ],
    ),
  );
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueAt = task.dueAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(task.dueAt!);
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFE9B5A4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ReminderService.instance.cancel(task.id);
        await ref.read(databaseProvider).deleteTask(task);
        if (task.photoPath != null) {
          final file = File(task.photoPath!);
          if (await file.exists()) await file.delete();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Checkbox.adaptive(
              value: task.isComplete,
              activeColor: const Color(0xFF537A67),
              onChanged: (value) async {
                try {
                  await ref
                      .read(databaseProvider)
                      .setComplete(task, value ?? false);
                  if (value == true) {
                    await ReminderService.instance.cancel(task.id);
                  } else if (task.dueAt != null) {
                    await ReminderService.instance.schedule(
                      taskId: task.id,
                      title: task.title,
                      at: DateTime.fromMillisecondsSinceEpoch(task.dueAt!),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Не вдалося оновити нагадування.'),
                      ),
                    );
                  }
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: task.isComplete
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isComplete
                          ? const Color(0xFF87948B)
                          : const Color(0xFF273C33),
                    ),
                  ),
                  if (task.photoPath != null)
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: Image.file(
                            File(task.photoPath!),
                            errorBuilder: (_, _, _) =>
                                const Text('Фото недоступне'),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Image.file(
                          File(task.photoPath!),
                          height: 64,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      task.category,
                      if (dueAt != null)
                        '${dueAt.day.toString().padLeft(2, '0')}.${dueAt.month.toString().padLeft(2, '0')} о ${dueAt.hour.toString().padLeft(2, '0')}:${dueAt.minute.toString().padLeft(2, '0')}',
                    ].join(' · '),
                    style: const TextStyle(
                      color: Color(0xFF839087),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.drag_indicator_rounded, color: Color(0xFFCAD3CC)),
          ],
        ),
      ),
    );
  }
}
