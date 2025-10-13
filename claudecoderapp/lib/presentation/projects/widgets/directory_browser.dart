import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../shared/controllers/file_tree_controller.dart';
import '../../../shared/models/file_tree_node.dart';
import '../../../shared/widgets/file_tree_view.dart';

final _directoryBrowserControllerProvider =
    StateNotifierProvider.autoDispose<FileTreeController, FileTreeState>((ref) {
      final apiService = ref.watch(apiServiceProvider);

      final controller = FileTreeController((path) async {
        final result = await apiService.browseFilesystem(path: path);
        final currentPath = result['path']?.toString();
        final suggestions = List<Map<String, dynamic>>.from(
          result['suggestions'] ?? [],
        );

        final nodes = suggestions
            .map(
              (entry) => FileTreeNode(
                id:
                    entry['path']?.toString() ??
                    entry['name']?.toString() ??
                    '',
                name:
                    entry['name']?.toString() ??
                    entry['path']?.toString() ??
                    '',
                isDirectory: true,
                metadata: entry,
              ),
            )
            .toList(growable: false);

        return FileTreeLoadResult(
          nodes: nodes,
          currentPath: currentPath,
          breadcrumbs: _buildBreadcrumbs(currentPath),
        );
      });

      Future.microtask(controller.refresh);
      return controller;
    });

class DirectoryBrowser extends HookConsumerWidget {
  final void Function(String) onDirectorySelected;

  const DirectoryBrowser({super.key, required this.onDirectorySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(_directoryBrowserControllerProvider);
    final controller = ref.watch(_directoryBrowserControllerProvider.notifier);
    final isCreating = useState(false);

    Future<void> showCreateFolderDialog() async {
      final textController = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Create New Folder',
            style: TextStyle(fontSize: 16),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Folder name',
              hintStyle: TextStyle(fontSize: 12),
            ),
            style: const TextStyle(fontSize: 13),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
            FilledButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(textController.text.trim());
                }
              },
              child: const Text('Create', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );

      final targetPath = treeState.currentPath;
      if (result != null && targetPath != null) {
        isCreating.value = true;
        try {
          final apiService = ref.read(apiServiceProvider);
          await apiService.createDirectory(
            parentPath: targetPath,
            dirName: result,
          );
          await controller.refresh(targetPath);
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create folder: $error')),
            );
          }
        } finally {
          isCreating.value = false;
        }
      }
    }

    void goUp() {
      final path = treeState.currentPath;
      if (path == null || path == '/') return;
      final parent = _parentPath(path);
      controller.refresh(parent.isEmpty ? '/' : parent);
    }

    void navigateToBreadcrumb(int index) {
      final pathParts = treeState.breadcrumbs.take(index + 1).toList();
      final path = '/${pathParts.join('/')}';
      controller.refresh(path);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (treeState.currentPath != null && treeState.currentPath != '/')
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: goUp,
                  tooltip: 'Go up',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  iconSize: 16,
                ),
              const Gap(4),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => controller.refresh(null),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 2,
                          ),
                          child: Icon(Icons.home, size: 14),
                        ),
                      ),
                      if (treeState.breadcrumbs.isNotEmpty) ...[
                        const Icon(Icons.chevron_right, size: 12),
                        ...treeState.breadcrumbs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final part = entry.value;
                          final isLast =
                              index == treeState.breadcrumbs.length - 1;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => navigateToBreadcrumb(index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    part,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isLast
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                      fontWeight: isLast
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isLast)
                                const Icon(Icons.chevron_right, size: 12),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(8),
        if (treeState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Error: ${treeState.errorMessage}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          controller.refresh(treeState.currentPath),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: treeState.currentPath != null && !isCreating.value
                    ? () => onDirectorySelected(treeState.currentPath!)
                    : null,
                icon: const Icon(Icons.check, size: 14),
                label: const Text(
                  'Select Current',
                  style: TextStyle(fontSize: 11),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
            const Gap(8),
            FilledButton.icon(
              onPressed: treeState.currentPath != null && !isCreating.value
                  ? showCreateFolderDialog
                  : null,
              icon: isCreating.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.create_new_folder, size: 14),
              label: const Text('New Folder', style: TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const Gap(8),
        Expanded(
          child: Stack(
            children: [
              FileTreeView(
                nodes: treeState.nodes,
                expandedNodeIds: treeState.expandedNodeIds,
                onToggleNode: controller.toggleNode,
                emptyLabel: 'No subdirectories',
                onDirectoryTap: (node) {
                  final data = node.metadata as Map<String, dynamic>?;
                  final path = data?['path']?.toString();
                  if (path != null) {
                    controller.refresh(path);
                    return true;
                  }
                  return false;
                },
              ),
              if (treeState.isLoading)
                const Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

List<String> _buildBreadcrumbs(String? currentPath) {
  if (currentPath == null || currentPath.isEmpty) {
    return const [];
  }
  final parts = currentPath.split('/');
  return parts.where((part) => part.isNotEmpty).toList();
}

String _parentPath(String path) {
  final segments = path.split('/')..removeLast();
  return segments.where((part) => part.isNotEmpty).join('/');
}
