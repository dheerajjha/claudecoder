import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/providers/providers.dart';

class DirectoryBrowser extends HookConsumerWidget {
  final Function(String) onDirectorySelected;

  const DirectoryBrowser({
    super.key,
    required this.onDirectorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = useState<String?>(null);
    final directories = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final breadcrumbs = useState<List<String>>([]);
    final isCreating = useState(false);

    Future<void> loadDirectory(String? path) async {
      isLoading.value = true;
      try {
        final apiService = ref.read(apiServiceProvider);
        final result = await apiService.browseFilesystem(path: path);

        currentPath.value = result['path'] as String;
        directories.value = List<Map<String, dynamic>>.from(
          result['suggestions'] ?? [],
        );

        // Build breadcrumbs from current path
        if (currentPath.value != null) {
          final parts = currentPath.value!.split('/');
          breadcrumbs.value = parts.where((p) => p.isNotEmpty).toList();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to browse directory: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    // Load home directory on first build
    useEffect(() {
      loadDirectory(null);
      return null;
    }, []);

    void navigateToPath(String path) {
      loadDirectory(path);
    }

    void navigateToBreadcrumb(int index) {
      // Rebuild path from breadcrumbs up to this index
      final pathParts = breadcrumbs.value.sublist(0, index + 1);
      final path = '/${pathParts.join('/')}';
      loadDirectory(path);
    }

    void goUp() {
      if (currentPath.value != null && currentPath.value != '/') {
        final parts = currentPath.value!.split('/');
        parts.removeLast();
        final parentPath = parts.isEmpty || parts.join('/').isEmpty
            ? '/'
            : parts.join('/');
        loadDirectory(parentPath);
      }
    }

    Future<void> showCreateFolderDialog() async {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create New Folder', style: TextStyle(fontSize: 16)),
          content: TextField(
            controller: controller,
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
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Create', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );

      if (result != null && currentPath.value != null) {
        isCreating.value = true;
        try {
          final apiService = ref.read(apiServiceProvider);
          await apiService.createDirectory(
            parentPath: currentPath.value!,
            dirName: result,
          );
          // Reload directory to show new folder
          await loadDirectory(currentPath.value);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create folder: $e')),
            );
          }
        } finally {
          isCreating.value = false;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Breadcrumbs and navigation - compact
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              // Up button
              if (currentPath.value != null && currentPath.value != '/')
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: goUp,
                  tooltip: 'Go up',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  iconSize: 16,
                ),
              const Gap(4),
              // Breadcrumbs
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => loadDirectory(null),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                          child: Icon(Icons.home, size: 14),
                        ),
                      ),
                      if (breadcrumbs.value.isNotEmpty) ...[
                        const Icon(Icons.chevron_right, size: 12),
                        ...breadcrumbs.value.asMap().entries.map((entry) {
                          final index = entry.key;
                          final part = entry.value;
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
                                      color: index == breadcrumbs.value.length - 1
                                          ? Theme.of(context).colorScheme.primary
                                          : null,
                                      fontWeight: index == breadcrumbs.value.length - 1
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                              if (index < breadcrumbs.value.length - 1)
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

        // Action buttons row - compact
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: currentPath.value != null && !isCreating.value
                    ? () => onDirectorySelected(currentPath.value!)
                    : null,
                icon: const Icon(Icons.check, size: 14),
                label: Text(
                  'Select Current',
                  style: const TextStyle(fontSize: 11),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
            const Gap(8),
            FilledButton.icon(
              onPressed: currentPath.value != null && !isCreating.value
                  ? showCreateFolderDialog
                  : null,
              icon: isCreating.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.create_new_folder, size: 14),
              label: Text(
                'New Folder',
                style: const TextStyle(fontSize: 11),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const Gap(8),

        // Directory list - compact
        Expanded(
          child: isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : directories.value.isEmpty
                  ? Center(
                      child: Text(
                        'No subdirectories',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: directories.value.length,
                      itemBuilder: (context, index) {
                        final dir = directories.value[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: const Icon(Icons.folder, size: 18),
                          title: Text(
                            dir['name'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            dir['path'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                          onTap: () => navigateToPath(dir['path']),
                          trailing: const Icon(Icons.chevron_right, size: 16),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
