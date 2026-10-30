import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cancels stale asynchronous requests before they can start speaking.
class CholeraVoice extends ChangeNotifier {
  CholeraVoice({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _tts.setStartHandler(() {
      if (_active && !muted && !_disposed) {
        speaking = true;
        notifyListeners();
      }
    });
    _tts.setCompletionHandler(_finished);
    _tts.setCancelHandler(() {
      if (speaking) _finished();
    });
    _tts.setErrorHandler((_) => _finished());
    ready = _load();
  }
  final FlutterTts _tts;
  late final Future<void> ready;
  bool muted = false, speaking = false;
  bool _active = false, _disposed = false, _muteChanged = false;
  int _generation = 0;
  bool get active => _active;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_disposed && !_muteChanged) {
      muted = prefs.getBool('choleraMuted') ?? false;
      notifyListeners();
    }
  }

  void _finished() {
    if (_disposed) return;
    _active = false;
    speaking = false;
    notifyListeners();
  }

  bool _current(int generation) =>
      !_disposed && !muted && generation == _generation;

  Future<String?> say(String text) async {
    final generation = ++_generation;
    try {
      await ready;
      if (!_current(generation)) return null;
      await _tts.stop();
      if (!_current(generation)) return null;
      _active = true;
      notifyListeners();
      final available = await _tts.isLanguageAvailable('uk-UA');
      if (!_current(generation)) return null;
      if (available != true) {
        _finished();
        return 'Український голос недоступний. Установи його в налаштуваннях синтезу мовлення Android. Фраза доступна текстом.';
      }
      await _tts.setLanguage('uk-UA');
      if (!_current(generation)) return null;
      await _tts.setSpeechRate(0.45);
      if (!_current(generation)) return null;
      await _tts.setQueueMode(0);
      if (!_current(generation)) return null;
      final result = await _tts.speak(text, focus: true);
      if (_current(generation) && result == 0) {
        _finished();
        return 'Не вдалося озвучити фразу. Перевір системний голос Android.';
      }
    } catch (_) {
      if (_current(generation)) {
        _finished();
        return 'Озвучення недоступне. Фраза залишається на екрані.';
      }
    }
    return null;
  }

  Future<void> stop() async {
    ++_generation;
    _finished();
    try {
      await _tts.stop();
    } catch (_) {
      /* Text UI remains usable. */
    }
  }

  Future<void> setMuted(bool value) async {
    _muteChanged = true;
    muted = value;
    await stop();
    final prefs = await SharedPreferences.getInstance();
    if (!_disposed && muted == value) {
      await prefs.setBool('choleraMuted', value);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _tts.stop().catchError((Object _) => null);
    super.dispose();
  }
}
