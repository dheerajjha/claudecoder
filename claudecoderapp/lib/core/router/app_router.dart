import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/projects/projects_screen.dart';
import '../../presentation/chat/chat_screen.dart';
import '../../presentation/files/files_screen.dart';
import '../providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Handle loading state
      if (authState.isLoading) {
        return null; // Stay on current route while loading
      }

      // Handle error state - treat as not logged in
      final isLoggedIn = authState.hasValue && authState.value != null;
      final isLoggingIn = state.uri.path == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const MainScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(path: '/files', builder: (context, state) => const FilesScreen()),
    ],
  );
});

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ProjectsScreen();
  }
}
