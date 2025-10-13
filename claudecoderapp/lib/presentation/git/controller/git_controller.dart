import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/git_status.dart';
import '../../../data/models/project.dart';
import '../../../data/services/api_service.dart';

class GitState {
  final GitStatus? status;
  final bool isLoading;
  final bool isInitializing;
  final bool isCommitting;
  final bool isPushing;
  final Set<String> selectedFiles;
  final String commitMessage;
  final String? errorMessage;
  final String? infoMessage;

  const GitState({
    required this.status,
    required this.isLoading,
    required this.isInitializing,
    required this.isCommitting,
    required this.isPushing,
    required this.selectedFiles,
    required this.commitMessage,
    required this.errorMessage,
    required this.infoMessage,
  });

  factory GitState.initial() {
    return const GitState(
      status: null,
      isLoading: false,
      isInitializing: false,
      isCommitting: false,
      isPushing: false,
      selectedFiles: {},
      commitMessage: '',
      errorMessage: null,
      infoMessage: null,
    );
  }

  GitState copyWith({
    GitStatus? status,
    bool? isLoading,
    bool? isInitializing,
    bool? isCommitting,
    bool? isPushing,
    Set<String>? selectedFiles,
    String? commitMessage,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return GitState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      isCommitting: isCommitting ?? this.isCommitting,
      isPushing: isPushing ?? this.isPushing,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      commitMessage: commitMessage ?? this.commitMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

final gitControllerProvider = StateNotifierProvider.autoDispose
    .family<GitController, GitState, Project>((ref, project) {
      final apiService = ref.watch(apiServiceProvider);
      final controller = GitController(
        apiService: apiService,
        project: project,
      );
      controller.refresh();
      return controller;
    });

class GitController extends StateNotifier<GitState> {
  GitController({required ApiService apiService, required this.project})
    : _apiService = apiService,
      super(GitState.initial());

  final ApiService _apiService;
  final Project project;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);
    try {
      final status = await _apiService.getGitStatus(project.name);
      final autoSelected = status.hasChanges
          ? <String>{
              ...status.modified,
              ...status.added,
              ...status.deleted,
              ...status.untracked,
            }
          : <String>{};
      state = state.copyWith(
        status: status,
        selectedFiles: autoSelected,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void setCommitMessage(String message) {
    state = state.copyWith(commitMessage: message);
  }

  void toggleFileSelection(String path) {
    final updated = Set<String>.from(state.selectedFiles);
    if (updated.contains(path)) {
      updated.remove(path);
    } else {
      updated.add(path);
    }
    state = state.copyWith(selectedFiles: updated);
  }

  void selectAll() {
    final status = state.status;
    if (status == null) return;
    final files = <String>{
      ...status.modified,
      ...status.added,
      ...status.deleted,
      ...status.untracked,
    };
    state = state.copyWith(selectedFiles: files);
  }

  void deselectAll() {
    state = state.copyWith(selectedFiles: <String>{});
  }

  Future<void> initializeGit() async {
    state = state.copyWith(isInitializing: true, clearError: true);
    try {
      await _apiService.initGit(project.name);
      state = state.copyWith(
        isInitializing: false,
        infoMessage: 'Git initialized successfully',
      );
      await refresh();
    } catch (error) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> commitChanges() async {
    final message = state.commitMessage.trim();
    if (message.isEmpty || state.selectedFiles.isEmpty) {
      return;
    }

    state = state.copyWith(
      isCommitting: true,
      clearError: true,
      clearInfo: true,
    );
    try {
      await _apiService.commitChanges(
        projectName: project.name,
        message: message,
        files: state.selectedFiles.toList(),
      );
      state = state.copyWith(
        isCommitting: false,
        commitMessage: '',
        selectedFiles: <String>{},
        infoMessage: 'Changes committed successfully',
      );
      await refresh();
    } catch (error) {
      state = state.copyWith(
        isCommitting: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> pushToRemote() async {
    state = state.copyWith(isPushing: true, clearError: true, clearInfo: true);
    try {
      final result = await _apiService.pushToRemote(project.name);
      state = state.copyWith(
        isPushing: false,
        infoMessage: result['output']?.toString() ?? 'Pushed successfully',
      );
      await refresh();
    } catch (error) {
      state = state.copyWith(isPushing: false, errorMessage: error.toString());
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }
}
