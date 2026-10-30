import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_navigation.dart';
import 'data/app_database.dart';
import 'features/schedule/schedule_page.dart';
import 'features/home/home_page.dart';
import 'features/tasks/add_task_page.dart';
import 'services/reminder_service.dart';
import 'services/capture_entrypoints.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    observers: [appRouteObserver],
    routes: [
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const SchedulePage(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/tasks/new',
        builder: (context, state) =>
            AddTaskPage(mode: state.uri.queryParameters['mode']),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderService.instance.initialize();
  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HomeBuddyApp(),
    ),
  );
  await CaptureEntrypoints.initialize(container.read(routerProvider));
}

class HomeBuddyApp extends ConsumerWidget {
  const HomeBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'HomeBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF537A67),
          surface: const Color(0xFFF7F5EF),
        ),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      locale: const Locale('uk'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('uk'), Locale('en')],
      routerConfig: router,
    );
  }
}
