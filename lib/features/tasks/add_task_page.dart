import 'dart:io';

import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../../services/reminder_service.dart';

class AddTaskPage extends ConsumerStatefulWidget {
  const AddTaskPage({super.key, this.mode});
  final String? mode;

  @override
  ConsumerState<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends ConsumerState<AddTaskPage>
    with WidgetsBindingObserver {
  final _speech = SpeechToText();
  final _picker = ImagePicker();
  String? _photo;
  bool _listening = false;
  bool _foreground = true;
  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final lost = await _picker.retrieveLostData();
        if (lost.files?.isNotEmpty ?? false) {
          if (mounted) setState(() => _photo = lost.files!.first.path);
        }
        if (!mounted) return;
        if (widget.mode == 'voice') await voice();
        if (widget.mode == 'photo') await photo();
      } catch (_) {
        message('Не вдалося відновити фото. Спробуй знову.');
      }
    });
  }

  Future<void> photo() async {
    try {
      final f = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (f != null && mounted) setState(() => _photo = f.path);
    } on PlatformException catch (error) {
      message(
        error.code.contains('access') || error.code.contains('permission')
            ? 'Доступ до камери заборонено. Перевір дозволи системної камери в налаштуваннях Android. Справу можна зберегти без фото.'
            : 'Не вдалося відкрити камеру. Перевір, чи встановлено застосунок камери. Справу можна зберегти без фото.',
      );
    } catch (_) {
      message('Камера недоступна. Справу можна зберегти без фото.');
    }
  }

  Future<void> voice() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    try {
      final ready = await _speech.initialize(
        onStatus: (s) {
          if (mounted) setState(() => _listening = s == 'listening');
        },
        onError: (error) {
          if (mounted) setState(() => _listening = false);
          message(
            error.errorMsg.contains('permission')
                ? 'Доступ до мікрофона заборонено. Увімкни його в налаштуваннях Android → Застосунки → HomeBuddy → Дозволи, або введи справу вручну.'
                : 'Не вдалося розпізнати голос. Спробуй ще раз або введи справу вручну.',
          );
        },
      );
      if (!ready) {
        message(
          'Розпізнавання недоступне. Перевір дозвіл мікрофона та системну службу мовлення.',
        );
        return;
      }
      if (!mounted || _saving || !_foreground) return;
      final locales = await _speech.locales();
      final ukrainian = locales
          .where((l) => l.localeId.startsWith('uk'))
          .firstOrNull;
      if (ukrainian == null) {
        message('Українську мову розпізнавання не встановлено в системі.');
        return;
      }
      if (!mounted || _saving || !_foreground) return;
      await _speech.listen(
        listenOptions: SpeechListenOptions(localeId: ukrainian.localeId),
        onResult: (r) {
          if (mounted && !_saving && _foreground) {
            setState(
              () => _titleController.text = r.recognizedWords.length > 120
                  ? r.recognizedWords.substring(0, 120)
                  : r.recognizedWords,
            );
          }
        },
      );
    } catch (_) {
      message('Голосове введення недоступне.');
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _dueAt;
  String _category = 'Дім';
  bool _saving = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      _speech.cancel().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.cancel().catchError((Object _) {});
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
    if (time == null || !mounted) return;
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
    if (_dueAt != null && !_dueAt!.isAfter(DateTime.now())) {
      message('Вибери майбутній час нагадування.');
      return;
    }
    setState(() => _saving = true);
    final title = _titleController.text.trim();
    final category = _category;
    final dueAt = _dueAt;
    final photo = _photo;
    final database = ref.read(databaseProvider);
    try {
      await _speech.cancel();
    } catch (_) {
      /* Save typed content even if recognizer stopped responding. */
    }
    String? storedPhoto;
    try {
      if (photo != null) {
        final dir = await getApplicationDocumentsDirectory();
        final target =
            '${dir.path}/task_${DateTime.now().microsecondsSinceEpoch}.jpg';
        await File(photo).copy(target);
        storedPhoto = target;
      }
    } catch (_) {
      message('Не вдалося зберегти фото.');
      if (mounted) setState(() => _saving = false);
      return;
    }
    int id;
    try {
      id = await database.addTask(
        title: title,
        category: category,
        dueAt: dueAt,
        photoPath: storedPhoto,
      );
    } catch (_) {
      if (storedPhoto != null) await File(storedPhoto).delete();
      message("Не вдалося зберегти справу.");
      if (mounted) setState(() => _saving = false);
      return;
    }
    var reminderScheduled = dueAt == null;
    try {
      if (dueAt != null) {
        final granted = await ReminderService.instance.requestPermission();
        if (granted) {
          await ReminderService.instance.schedule(
            taskId: id,
            title: title,
            at: dueAt,
          );
          reminderScheduled = true;
        }
      }
    } catch (_) {
      reminderScheduled = false;
    }
    if (!mounted) return;
    if (!reminderScheduled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Справу збережено без сповіщення. Перевір Android → HomeBuddy → Сповіщення та дозволений час у розкладі.',
          ),
        ),
      );
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Нова справа'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
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
                autofocus: widget.mode != 'voice' && widget.mode != 'photo',
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                readOnly: _saving,
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
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : voice,
                    icon: Icon(_listening ? Icons.stop : Icons.mic),
                    label: Text(_listening ? 'Зупинити' : 'Продиктувати'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : photo,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Фото несправності'),
                  ),
                ],
              ),
              if (_photo != null) ...[
                Image.file(File(_photo!), height: 180, fit: BoxFit.contain),
                TextButton(
                  onPressed: () => setState(() => _photo = null),
                  child: const Text('Прибрати фото'),
                ),
              ],
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
                const Text(
                  'Нагадування буде перенесено на дозволений час у твоєму розкладі.',
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
