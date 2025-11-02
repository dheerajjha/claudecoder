import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../data/models/file_item.dart';
import '../../shared/widgets/file_tree_view.dart';
import '../file_viewer/file_viewer_screen.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Files')),
        body: const Center(child: Text('Please select a project first')),
      );
    }

    final controllerProvider = projectFileTreeControllerProvider(project);
    final treeState = ref.watch(controllerProvider);
    final controller = ref.watch(controllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Files - ${project.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search files...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: controller.setSearchQuery,
            ),
          ),
          if (treeState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error: ${treeState.errorMessage}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const Gap(8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => controller.refresh(),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                FileTreeView(
                  nodes: treeState.nodes,
                  expandedNodeIds: treeState.expandedNodeIds,
                  onToggleNode: controller.toggleNode,
                  searchQuery: treeState.searchQuery,
                  showFileSize: true,
                  onFileTap: (node) {
                    final fileItem = node.metadata is FileItem
                        ? node.metadata as FileItem
                        : null;
                    if (fileItem != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FileViewerScreen(file: fileItem),
                        ),
                      );
                    }
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
      ),
    );
  }
}
