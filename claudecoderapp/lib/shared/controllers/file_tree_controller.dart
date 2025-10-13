import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/file_tree_node.dart';

typedef FileTreeLoader = Future<FileTreeLoadResult> Function(String? path);

@immutable
class FileTreeLoadResult {
  final String? currentPath;
  final List<String> breadcrumbs;
  final List<FileTreeNode> nodes;

  const FileTreeLoadResult({
    required this.nodes,
    this.currentPath,
    this.breadcrumbs = const [],
  });
}

@immutable
class FileTreeState {
  final bool isLoading;
  final List<FileTreeNode> nodes;
  final String? errorMessage;
  final Set<String> expandedNodeIds;
  final String searchQuery;
  final String? currentPath;
  final List<String> breadcrumbs;

  const FileTreeState({
    required this.isLoading,
    required this.nodes,
    required this.expandedNodeIds,
    required this.searchQuery,
    required this.breadcrumbs,
    this.errorMessage,
    this.currentPath,
  });

  factory FileTreeState.initial() {
    return const FileTreeState(
      isLoading: false,
      nodes: [],
      expandedNodeIds: {},
      searchQuery: '',
      breadcrumbs: [],
    );
  }

  FileTreeState copyWith({
    bool? isLoading,
    List<FileTreeNode>? nodes,
    String? errorMessage,
    Set<String>? expandedNodeIds,
    String? searchQuery,
    String? currentPath,
    List<String>? breadcrumbs,
  }) {
    return FileTreeState(
      isLoading: isLoading ?? this.isLoading,
      nodes: nodes ?? this.nodes,
      errorMessage: errorMessage,
      expandedNodeIds: expandedNodeIds ?? this.expandedNodeIds,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPath: currentPath ?? this.currentPath,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
    );
  }
}

class FileTreeController extends StateNotifier<FileTreeState> {
  FileTreeController(this._loader) : super(FileTreeState.initial());

  final FileTreeLoader _loader;

  Future<void> refresh([String? path]) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _loader(path);
      state = state.copyWith(
        isLoading: false,
        nodes: result.nodes,
        currentPath: result.currentPath,
        breadcrumbs: result.breadcrumbs,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void toggleNode(String nodeId) {
    final updated = Set<String>.from(state.expandedNodeIds);
    if (updated.contains(nodeId)) {
      updated.remove(nodeId);
    } else {
      updated.add(nodeId);
    }
    state = state.copyWith(expandedNodeIds: updated);
  }

  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}
