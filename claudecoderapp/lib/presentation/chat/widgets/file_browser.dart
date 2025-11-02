import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/file_item.dart';
import '../../../shared/widgets/file_tree_view.dart';
import '../../file_viewer/file_viewer_screen.dart';

class FileBrowser extends HookConsumerWidget {
  const FileBrowser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);

    if (project == null) {
      return const Center(child: Text('No project selected'));
    }

    final controllerProvider = projectFileTreeControllerProvider(project);
    final treeState = ref.watch(controllerProvider);
    final controller = ref.watch(controllerProvider.notifier);
    final searchController = useTextEditingController(
      text: treeState.searchQuery,
    );

    useEffect(() {
      if (searchController.text != treeState.searchQuery) {
        searchController.text = treeState.searchQuery;
        searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: searchController.text.length),
        );
      }
      return null;
    }, [treeState.searchQuery, searchController]);

    useEffect(() {
      void listener() {
        controller.setSearchQuery(searchController.text);
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController, controller]);

    ref.listen<int>(fileBrowserRefreshProvider, (_, __) {
      controller.refresh();
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const Gap(8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh files',
                onPressed: () => controller.refresh(),
              ),
            ],
          ),
        ),
        if (treeState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    FilledButton(
                      onPressed: () => controller.refresh(),
                      child: const Text('Retry'),
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
                emptyLabel: 'No files found',
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
    );
  }
}
