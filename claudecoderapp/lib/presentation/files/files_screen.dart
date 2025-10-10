import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/providers/providers.dart';
import '../../data/models/file_item.dart';

final filesProvider = FutureProvider.autoDispose<List<FileItem>>((ref) async {
  final project = ref.watch(selectedProjectProvider);
  if (project == null) throw Exception('No project selected');

  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getFiles(project.name);
});

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);
    final filesAsync = ref.watch(filesProvider);

    if (selectedProject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Files')),
        body: const Center(
          child: Text('Please select a project first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Files - ${selectedProject.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(filesProvider),
          ),
        ],
      ),
      body: filesAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return const Center(child: Text('No files found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return FileItemWidget(item: files[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const Gap(16),
              Text('Error: ${error.toString()}'),
              const Gap(16),
              FilledButton(
                onPressed: () => ref.invalidate(filesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FileItemWidget extends StatelessWidget {
  final FileItem item;
  final int depth;

  const FileItemWidget({
    super.key,
    required this.item,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDirectory = item.type == 'directory';

    if (isDirectory && item.children.isNotEmpty) {
      return ExpansionTile(
        leading: Icon(
          Icons.folder,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(item.name),
        subtitle: Text('${item.children.length} items'),
        tilePadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16),
        children: item.children
            .map((child) => FileItemWidget(
                  item: child,
                  depth: depth + 1,
                ))
            .toList(),
      );
    }

    return ListTile(
      leading: Icon(
        isDirectory ? Icons.folder : Icons.insert_drive_file,
        color: isDirectory
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
      ),
      title: Text(item.name),
      subtitle: item.size != null
          ? Text(_formatFileSize(item.size!))
          : null,
      contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16),
      onTap: () {
        if (!isDirectory) {
          // TODO: Open file viewer/editor
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${item.name}...')),
          );
        }
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
