import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../../services/reminder_service.dart';

class AddTaskPage extends ConsumerStatefulWidget {
  const AddTaskPage({super.key});

  @override
  ConsumerState<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends ConsumerState<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _dueAt;
  String _category = 'Дім';
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('uk'),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _dueAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return;
    setState(
      () => _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final database = ref.read(databaseProvider);
    final id = await database.addTask(
      title: _titleController.text,
      category: _category,
      dueAt: _dueAt,
    );
    var reminderScheduled = _dueAt == null;
    if (_dueAt != null) {
      final granted = await ReminderService.instance.requestPermission();
      if (granted) {
        await ReminderService.instance.schedule(
          taskId: id,
          title: _titleController.text.trim(),
          at: _dueAt!,
        );
        reminderScheduled = true;
      }
    }
    if (!mounted) return;
    if (!reminderScheduled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Справу збережено. Дозволь сповіщення в Android, щоб отримати нагадування.',
          ),
        ),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Нова справа')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            children: [
              const Text(
                'Що потрібно зробити?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Наприклад, полити квіти',
                  labelText: 'Назва справи',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Введи назву справи'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Категорія'),
                items: const ['Дім', 'Прибирання', 'Покупки', 'Інше']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? 'Дім'),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(
                  _dueAt == null
                      ? 'Додати нагадування'
                      : '${_dueAt!.day.toString().padLeft(2, '0')}.${_dueAt!.month.toString().padLeft(2, '0')}.${_dueAt!.year} о ${_dueAt!.hour.toString().padLeft(2, '0')}:${_dueAt!.minute.toString().padLeft(2, '0')}',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_dueAt != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _dueAt = null),
                    child: const Text('Прибрати нагадування'),
                  ),
                ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF537A67),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Зберегти справу'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
