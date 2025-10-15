import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/providers/providers.dart';
import 'data/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize base URL from storage
  final storage = StorageService();
  final savedBaseUrl = await storage.getBaseUrl();

  print('🚀 APP STARTING');
  print('📡 Loaded base URL from storage: $savedBaseUrl');

  runApp(
    ProviderScope(
      overrides: [
        baseUrlProvider.overrideWith((ref) => savedBaseUrl),
      ],
      child: const ClaudeCoderApp(),
    ),
  );
}

class ClaudeCoderApp extends ConsumerWidget {
  const ClaudeCoderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Claude Coder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
