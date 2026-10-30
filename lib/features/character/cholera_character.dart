import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CholeraEmotion { joy, surprise, grumpy, sleepy }

const choleraPhrases = {
  CholeraEmotion.joy: [
    'Порядок сам себе не наведе. Але ми йому натякнемо!',
    'Одна справа готова — диван уже пишається тобою!',
  ],
  CholeraEmotion.surprise: ['Ого! Це список справ чи домашній квест?'],
  CholeraEmotion.grumpy: ['Пил знову оселився без дозволу. Виселяємо!'],
  CholeraEmotion.sleepy: ['Я не сплю. Я економлю домашню енергію.'],
};

class CholeraCharacter extends StatefulWidget {
  const CholeraCharacter({super.key, this.size = 120});
  final double size;
  @override
  State<CholeraCharacter> createState() => _CholeraCharacterState();
}

class _CholeraCharacterState extends State<CholeraCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  final FlutterTts _tts = FlutterTts();
  CholeraEmotion _emotion = CholeraEmotion.joy;
  bool _muted = false, _speaking = false;
  int _phrase = 0;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _muted = p.getBool('choleraMuted') ?? false);
    });
    _tts.setStartHandler(() {
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(_stopMouth);
    _tts.setCancelHandler(_stopMouth);
    _tts.setErrorHandler((_) => _stopMouth());
  }

  void _stopMouth() {
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _say() async {
    final phrases = choleraPhrases[_emotion]!;
    final text = phrases[_phrase++ % phrases.length];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    if (_muted) return;
    try {
      if (await _tts.isLanguageAvailable('uk-UA') != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Український голос не встановлено в системі. Фрази доступні текстом.',
              ),
            ),
          );
        }
        return;
      }
      await _tts.setLanguage('uk-UA');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    } catch (_) {
      _stopMouth();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: _say,
        child: Semantics(
          label: 'Холера: торкнися, щоб почути фразу',
          button: true,
          child: AnimatedBuilder(
            animation: _clock,
            builder: (_, _) => SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _CholeraPainter(_clock.value, _emotion, _speaking),
              ),
            ),
          ),
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _muted ? 'Увімкнути звук' : 'Вимкнути звук',
            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
            onPressed: () async {
              setState(() => _muted = !_muted);
              await _tts.stop();
              final p = await SharedPreferences.getInstance();
              await p.setBool('choleraMuted', _muted);
            },
          ),
          PopupMenuButton<CholeraEmotion>(
            tooltip: 'Настрій Холери',
            icon: const Icon(Icons.face),
            onSelected: (e) {
              setState(() => _emotion = e);
              _say();
            },
            itemBuilder: (_) => [
              for (final e in CholeraEmotion.values)
                PopupMenuItem(
                  value: e,
                  child: Text(
                    [
                      'Радість',
                      'Здивування',
                      'Невдоволення',
                      'Сонливість',
                    ][e.index],
                  ),
                ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _CholeraPainter extends CustomPainter {
  _CholeraPainter(this.time, this.emotion, this.speaking);
  final double time;
  final CholeraEmotion emotion;
  final bool speaking;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(0, math.sin(time * math.pi * 2) * 2);
    final body = Paint()..color = const Color(0xFFFFC96C);
    final cheek = Paint()..color = const Color(0xFFEE9C82);
    final ink = Paint()
      ..color = const Color(0xFF493A35)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final silhouette = Path()
      ..moveTo(21, 95)
      ..cubicTo(11, 84, 16, 70, 21, 62)
      ..cubicTo(13, 41, 28, 18, 51, 15)
      ..cubicTo(79, 9, 101, 25, 101, 51)
      ..cubicTo(115, 66, 112, 91, 98, 101)
      ..cubicTo(80, 113, 37, 111, 21, 95)
      ..close();
    canvas.drawPath(silhouette, body);
    canvas.drawPath(silhouette, ink);

    final shine = Paint()..color = const Color(0xFFFFD995);
    canvas.drawOval(const Rect.fromLTWH(28, 25, 24, 12), shine);
    final blink = time > .90 && time < .94;
    final eyeY = emotion == CholeraEmotion.sleepy ? 64.0 : 60.0;
    final look = math.sin(time * math.pi * 2) * 3;
    for (final x in [44.0, 76.0]) {
      if (blink || emotion == CholeraEmotion.sleepy) {
        canvas.drawLine(Offset(x - 4, eyeY), Offset(x + 4, eyeY), ink);
      } else {
        canvas.drawCircle(
          Offset(x + look, eyeY),
          emotion == CholeraEmotion.surprise ? 6 : 3.6,
          ink..style = PaintingStyle.fill,
        );
        ink.style = PaintingStyle.stroke;
      }
    }
    if (emotion == CholeraEmotion.grumpy) {
      canvas.drawLine(const Offset(39, 49), const Offset(49, 54), ink);
      canvas.drawLine(const Offset(71, 54), const Offset(81, 49), ink);
    }
    canvas.drawLine(
      const Offset(21, 81),
      Offset(9, 77 + math.sin(time * 20) * (speaking ? 8 : 2)),
      ink,
    );
    canvas.drawLine(
      const Offset(98, 81),
      Offset(111, 77 - math.sin(time * 20) * (speaking ? 8 : 2)),
      ink,
    );
    ink.style = PaintingStyle.fill;
    canvas.drawOval(const Rect.fromLTWH(25, 68, 18, 9), cheek);
    canvas.drawOval(const Rect.fromLTWH(77, 68, 18, 9), cheek);
    ink.style = PaintingStyle.stroke;
    if (speaking || emotion == CholeraEmotion.surprise) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(60, 76),
          width: 14,
          height: speaking ? 5 + 12 * math.sin(time * 90).abs() : 18,
        ),
        ink..style = PaintingStyle.fill,
      );
      ink.style = PaintingStyle.stroke;
    } else if (emotion == CholeraEmotion.grumpy) {
      canvas.drawLine(const Offset(50, 77), const Offset(70, 77), ink);
    } else {
      canvas.drawArc(const Rect.fromLTWH(49, 63, 22, 16), .2, 2.7, false, ink);
    }

    final leaf = Paint()..color = const Color(0xFF6C9874);
    final leafPath = Path()
      ..moveTo(59, 17)
      ..cubicTo(49, 5, 53, 0, 65, 10)
      ..cubicTo(75, 0, 84, 5, 70, 18)
      ..close();
    canvas.drawPath(leafPath, leaf);
    canvas.drawLine(
      const Offset(66, 14),
      const Offset(71, 7),
      ink..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
