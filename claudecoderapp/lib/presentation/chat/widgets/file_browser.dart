import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/file_item.dart';

class FileBrowser extends HookConsumerWidget {
  const FileBrowser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);
    final refreshTrigger = ref.watch(fileBrowserRefreshProvider);
    final files = useState<List<FileItem>>([]);
    final isLoading = useState(false);
    final expandedDirs = useState<Set<String>>({});
    final searchQuery = useState('');

    // Load files function
    Future<void> loadFiles() async {
      if (selectedProject == null) return;

      isLoading.value = true;
      try {
        final apiService = ref.read(apiServiceProvider);
        final fileList = await apiService.getFiles(selectedProject.name);
        files.value = fileList;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load files: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    // Load files when project changes or refresh is triggered
    useEffect(() {
      loadFiles();
      return null;
    }, [selectedProject, refreshTrigger]);

    void toggleDirectory(String path) {
      final newExpanded = Set<String>.from(expandedDirs.value);
      if (newExpanded.contains(path)) {
        newExpanded.remove(path);
      } else {
        newExpanded.add(path);
      }
      expandedDirs.value = newExpanded;
    }

    Widget buildFileTree(List<FileItem> items, int level) {
      final filteredItems = items.where((item) {
        if (searchQuery.value.isEmpty) return true;
        return item.name.toLowerCase().contains(searchQuery.value.toLowerCase());
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: filteredItems.map((item) {
          final isExpanded = expandedDirs.value.contains(item.path);
          final indent = level * 16.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () {
                  if (item.type == 'directory') {
                    toggleDirectory(item.path);
                  } else {
                    // TODO: Show file viewer
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File viewer coming soon: ${item.name}')),
                    );
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12 + indent,
                    top: 8,
                    bottom: 8,
                    right: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.type == 'directory'
                            ? (isExpanded ? Icons.folder_open : Icons.folder)
                            : _getFileIcon(item.name),
                        size: 20,
                        color: item.type == 'directory'
                            ? Colors.blue
                            : Theme.of(context).iconTheme.color,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (item.type == 'file' && item.size != null)
                        Text(
                          _formatFileSize(item.size!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              if (item.type == 'directory' && isExpanded && item.children.isNotEmpty)
                buildFileTree(item.children, level + 1),
            ],
          );
        }).toList(),
      );
    }

    if (selectedProject == null) {
      return const Center(child: Text('No project selected'));
    }

    if (isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header with search and refresh
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => searchQuery.value = value,
                ),
              ),
              const Gap(8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh files',
                onPressed: isLoading.value ? null : loadFiles,
              ),
            ],
          ),
        ),
        // File tree
        Expanded(
          child: files.value.isEmpty
              ? const Center(child: Text('No files found'))
              : SingleChildScrollView(
                  child: buildFileTree(files.value, 0),
                ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const codeExts = ['dart', 'js', 'jsx', 'ts', 'tsx', 'py', 'java', 'cpp'];
    const docExts = ['md', 'txt', 'pdf'];
    const imageExts = ['png', 'jpg', 'jpeg', 'gif', 'svg'];

    if (codeExts.contains(ext)) return Icons.code;
    if (docExts.contains(ext)) return Icons.description;
    if (imageExts.contains(ext)) return Icons.image;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
