import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_buddy/app_navigation.dart';
import 'package:home_buddy/features/character/cholera_character.dart';
import 'package:home_buddy/services/cholera_voice.dart';

class FakeTts extends FlutterTts {
  final spoken = <String>[];
  int stops = 0;
  bool available = true;
  Completer<bool>? languageGate;
  @override
  Future<dynamic> stop() async {
    stops++;
    return 1;
  }

  @override
  Future<dynamic> isLanguageAvailable(String language) async =>
      languageGate == null ? available : languageGate!.future;
  @override
  Future<dynamic> setLanguage(String language) async => 1;
  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;
  @override
  Future<dynamic> setQueueMode(int mode) async => 1;
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    startHandler?.call();
    return 1;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'latest tap wins and stop prevents pending voice from starting',
    () async {
      final engine = FakeTts()..languageGate = Completer<bool>();
      final voice = CholeraVoice(tts: engine);
      addTearDown(voice.dispose);
      await voice.ready;
      final first = voice.say('first');
      await Future<void>.delayed(Duration.zero);
      final second = voice.say('second');
      await Future<void>.delayed(Duration.zero);
      engine.languageGate!.complete(true);
      await Future.wait([first, second]);
      expect(engine.spoken, ['second']);
      expect(voice.speaking, isTrue);
      await voice.stop();
      engine.startHandler?.call();
      expect(voice.speaking, isFalse);
      engine.languageGate = Completer<bool>();
      final pending = voice.say('late');
      await Future<void>.delayed(Duration.zero);
      await voice.stop();
      engine.languageGate!.complete(true);
      await pending;
      expect(engine.spoken, ['second']);
    },
  );
  test(
    'mute cancels, persists and survives recreation; missing voice is explicit',
    () async {
      final engine = FakeTts();
      final voice = CholeraVoice(tts: engine);
      await voice.ready;
      await voice.say('one');
      await voice.setMuted(true);
      expect(voice.speaking, isFalse);
      await voice.say('silent');
      expect(engine.spoken, ['one']);
      voice.dispose();
      final restored = CholeraVoice(tts: engine);
      addTearDown(restored.dispose);
      await restored.ready;
      expect(restored.muted, isTrue);
      await restored.setMuted(false);
      engine.available = false;
      expect(
        await restored.say('missing'),
        contains('Український голос недоступний'),
      );
      expect(restored.active, isFalse);
    },
  );
  test('dispose cancels a request during voice discovery', () async {
    final engine = FakeTts()..languageGate = Completer<bool>();
    final voice = CholeraVoice(tts: engine);
    await voice.ready;
    final pending = voice.say('late');
    await Future<void>.delayed(Duration.zero);
    voice.dispose();
    engine.languageGate!.complete(true);
    await pending;
    expect(engine.spoken, isEmpty);
  });
  testWidgets('navigation and backgrounding stop speech without resuming it', (
    tester,
  ) async {
    final engine = FakeTts();
    final voice = CholeraVoice(tts: engine);
    await voice.ready;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appRouteObserver],
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                CholeraCharacter(voice: voice),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('Next')),
                    ),
                  ),
                  child: const Text('Next page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await voice.say('hello');
    await tester.pump();
    await tester.tap(find.text('Next page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(voice.speaking, isFalse);
    Navigator.of(tester.element(find.text('Next'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await voice.say('again');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(voice.speaking, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(engine.spoken, ['hello', 'again']);
  });
}
