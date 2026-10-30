import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_navigation.dart';
import '../../services/cholera_voice.dart';

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
  const CholeraCharacter({super.key, this.size = 120, this.voice});
  final CholeraVoice? voice;
  final double size;
  @override
  State<CholeraCharacter> createState() => _CholeraCharacterState();
}

class _CholeraCharacterState extends State<CholeraCharacter>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  late final CholeraVoice _voice = (widget.voice ?? CholeraVoice())
    ..addListener(_changed);
  ModalRoute<void>? _route;
  CholeraEmotion _emotion = CholeraEmotion.joy;
  int _phrase = 0;
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voice;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _voice.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _voice.stop();
      _clock.stop();
    } else {
      _clock.repeat();
    }
  }

  Future<void> _say() async {
    if (_voice.active) {
      await _voice.stop();
      return;
    }
    final phrases = choleraPhrases[_emotion]!;
    final text = phrases[_phrase++ % phrases.length];
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(text)));
    final issue = await _voice.say(text);
    if (mounted && issue != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(issue)));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _voice.removeListener(_changed);
    _voice.dispose();
    _clock.dispose();
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
                painter: _CholeraPainter(
                  _clock.value,
                  _emotion,
                  _voice.speaking,
                ),
              ),
            ),
          ),
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _voice.muted ? 'Увімкнути звук' : 'Вимкнути звук',
            icon: Icon(_voice.muted ? Icons.volume_off : Icons.volume_up),
            onPressed: () => _voice.setMuted(!_voice.muted),
          ),
          if (_voice.active)
            IconButton(
              tooltip: 'Зупинити озвучення',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: _voice.stop,
              constraints: const BoxConstraints.tightFor(width: 32),
              padding: EdgeInsets.zero,
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
