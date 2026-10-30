import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

class CaptureEntrypoints {
  static StreamSubscription<Uri?>? _subscription;
  static Future<void> initialize(GoRouter router) async {
    void open(String mode) {
      if (const ['new', 'voice', 'photo'].contains(mode)) {
        router.go('/tasks/new?mode=$mode');
      }
    }

    const shortcuts = QuickActions();
    await shortcuts.initialize(open);
    await shortcuts.setShortcutItems(const [
      ShortcutItem(type: 'new', localizedTitle: 'Нова справа'),
      ShortcutItem(type: 'voice', localizedTitle: 'Продиктувати справу'),
      ShortcutItem(type: 'photo', localizedTitle: 'Фото несправності'),
    ]);
    await _subscription?.cancel();
    _subscription = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) open('new');
    });
    final launch = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (launch != null) open('new');
  }
}
