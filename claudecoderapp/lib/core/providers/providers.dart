import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/models/project.dart';
import '../../data/models/user.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/websocket_service.dart';
import '../../shared/controllers/file_tree_controller.dart';
import '../../shared/utils/file_tree_mappers.dart';

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Base URL Provider - holds current base URL
final baseUrlProvider = StateProvider<String?>((ref) => null);

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final baseUrl = ref.watch(baseUrlProvider);
  print('🔧 API Service Provider: Creating ApiService with baseUrl: $baseUrl');
  return ApiService(storage, baseUrl: baseUrl);
});

// WebSocket Service Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final ws = WebSocketService();
  ref.onDispose(() => ws.dispose());
  return ws;
});

// Auth State Provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<User?>>((ref) {
      return AuthStateNotifier(
        ref.watch(apiServiceProvider),
        ref.watch(storageServiceProvider),
      );
    });

class AuthStateNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _apiService;
  final StorageService _storage;

  AuthStateNotifier(this._apiService, this._storage)
    : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = const AsyncValue.loading();
    try {
      final token = await _storage.getToken();
      final username = await _storage.getUsername();

      if (token != null && username != null) {
        state = AsyncValue.data(
          User(
            id: 0, // Will be refreshed on API call
            username: username,
            token: token,
          ),
        );
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _apiService.login(username, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = const AsyncValue.data(null);
  }
}

// Projects Provider
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getProjects();
});

// Project file tree controller
final projectFileTreeControllerProvider = StateNotifierProvider.autoDispose
    .family<FileTreeController, FileTreeState, Project>((ref, project) {
      final apiService = ref.watch(apiServiceProvider);
      final controller = FileTreeController((_) async {
        final files = await apiService.getFiles(project.name);
        return FileTreeLoadResult(
          nodes: files.map(fileItemToNode).toList(growable: false),
          currentPath: project.fullPath,
        );
      });

      Future.microtask(controller.refresh);
      return controller;
    });

// Selected Project Provider
final selectedProjectProvider = StateProvider<Project?>((ref) => null);

// Selected Session Provider
final selectedSessionProvider = StateProvider<String?>((ref) => null);

// File Browser Refresh Trigger Provider
// Increment this to trigger a refresh of the file browser
final fileBrowserRefreshProvider = StateProvider<int>((ref) => 0);

// Git Refresh Trigger Provider
// Increment this to trigger a refresh of git status
final gitRefreshProvider = StateProvider<int>((ref) => 0);
