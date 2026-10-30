import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../../services/reminder_service.dart';
import 'life_schedule.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});
  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  LifeSchedule? _schedule;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    LifeSchedule.load().then((s) {
      if (mounted) setState(() => _schedule = s);
    });
  }

  Widget time(String title, int value, void Function(int) change) => ListTile(
    title: Text(title),
    trailing: Text(
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}',
    ),
    onTap: () async {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60),
      );
      if (t != null && mounted) setState(() => change(t.hour * 60 + t.minute));
    },
  );
  Widget number(
    String title,
    int value,
    void Function(int) change, {
    int min = 0,
    int max = 240,
    int step = 15,
  }) => Row(
    children: [
      Expanded(child: Text('$title: $value')),
      IconButton(
        onPressed: value > min
            ? () => setState(() => change((value - step).clamp(min, max)))
            : null,
        icon: const Icon(Icons.remove),
      ),
      IconButton(
        onPressed: value < max
            ? () => setState(() => change((value + step).clamp(min, max)))
            : null,
        icon: const Icon(Icons.add),
      ),
    ],
  );
  Future<void> save() async {
    setState(() => _saving = true);
    try {
      final s = _schedule!;
      if (s.sleepStart == s.sleepEnd) {
        throw StateError('Початок і завершення сну повинні відрізнятися.');
      }
      s.nextAllowed(DateTime.now());
      await s.save();
      final db = ref.read(databaseProvider);
      final tasks = await db.select(db.tasks).get();
      final pending = await ReminderService.instance.pendingIds();
      for (final task in tasks) {
        await ReminderService.instance.cancel(task.id);
        if (!task.isComplete &&
            task.dueAt != null &&
            (task.dueAt! > DateTime.now().millisecondsSinceEpoch ||
                pending.contains(task.id))) {
          await ReminderService.instance.schedule(
            taskId: task.id,
            title: task.title,
            at: task.dueAt! > DateTime.now().millisecondsSinceEpoch
                ? DateTime.fromMillisecondsSinceEpoch(task.dueAt!)
                : DateTime.now().add(const Duration(minutes: 1)),
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Графік збережено. Майбутні нагадування переплановано.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не вдалося застосувати графік: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _schedule;
    return Scaffold(
      appBar: AppBar(title: const Text('Мій розклад')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Нагадування переносяться на найближчий вільний час поза роботою, дорогою, відпочинком і сном.',
                ),
                SwitchListTile(
                  title: const Text('Позмінний графік'),
                  value: s.shift,
                  onChanged: (v) => setState(() => s.shift = v),
                ),
                if (!s.shift)
                  Wrap(
                    spacing: 4,
                    children: [
                      for (var i = 1; i <= 7; i++)
                        FilterChip(
                          label: Text(
                            ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'][i - 1],
                          ),
                          selected: s.weekdays.contains(i),
                          onSelected: (v) => setState(
                            () => s.weekdays = v
                                ? [...s.weekdays, i]
                                : s.weekdays.where((d) => d != i).toList(),
                          ),
                        ),
                    ],
                  ),
                if (!s.shift) const Text('Невибрані дні — вихідні.'),
                if (s.shift) ...[
                  number(
                    'Робочих днів поспіль',
                    s.onDays,
                    (v) => s.onDays = v,
                    min: 1,
                    max: 14,
                    step: 1,
                  ),
                  number(
                    'Вихідних поспіль',
                    s.offDays,
                    (v) => s.offDays = v,
                    min: 1,
                    max: 14,
                    step: 1,
                  ),
                  ListTile(
                    title: const Text('Перший робочий день циклу'),
                    subtitle: Text(
                      '${s.anchor.day}.${s.anchor.month}.${s.anchor.year}',
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: s.anchor,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null && mounted) setState(() => s.anchor = d);
                    },
                  ),
                ],
                time('Початок роботи', s.workStart, (v) => s.workStart = v),
                time('Завершення роботи', s.workEnd, (v) => s.workEnd = v),
                number('Дорога додому, хв', s.commute, (v) => s.commute = v),
                number(
                  'Відпочинок після роботи, хв',
                  s.rest,
                  (v) => s.rest = v,
                ),
                time('Час сну', s.sleepStart, (v) => s.sleepStart = v),
                time('Пробудження', s.sleepEnd, (v) => s.sleepEnd = v),
                time(
                  'Нагадування від',
                  s.allowedStart,
                  (v) => s.allowedStart = v,
                ),
                time('Нагадування до', s.allowedEnd, (v) => s.allowedEnd = v),
                FilledButton(
                  onPressed: _saving ? null : save,
                  child: Text(_saving ? 'Збереження…' : 'Зберегти графік'),
                ),
              ],
            ),
    );
  }
}
