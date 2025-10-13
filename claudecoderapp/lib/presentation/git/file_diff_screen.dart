import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/providers/providers.dart';
import 'widgets/diff_viewer.dart';

class FileDiffScreen extends HookConsumerWidget {
  final List<String> files;
  final int initialIndex;
  final String category;
  final String categoryColor;

  const FileDiffScreen({
    super.key,
    required this.files,
    required this.initialIndex,
    required this.category,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);
    final currentIndex = useState(initialIndex);
    final fileDiff = useState<String>('');
    final isLoading = useState(false);

    Future<void> loadFileDiff(int index) async {
      if (selectedProject == null || index < 0 || index >= files.length) return;

      isLoading.value = true;
      fileDiff.value = '';

      try {
        final apiService = ref.read(apiServiceProvider);
        final diff = await apiService.getGitDiff(selectedProject.name, files[index]);
        fileDiff.value = diff.diff;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load diff: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> discardChanges() async {
      if (selectedProject == null) return;

      final currentFile = files[currentIndex.value];

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes'),
          content: Text('Are you sure you want to discard changes in $currentFile?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.discardChanges(
          projectName: selectedProject.name,
          filePath: currentFile,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes discarded')),
          );
          Navigator.pop(context, true); // Return true to trigger refresh
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to discard changes: $e')),
          );
        }
      }
    }

    void goToPrevious() {
      if (currentIndex.value > 0) {
        currentIndex.value--;
        loadFileDiff(currentIndex.value);
      }
    }

    void goToNext() {
      if (currentIndex.value < files.length - 1) {
        currentIndex.value++;
        loadFileDiff(currentIndex.value);
      }
    }

    // Load initial diff
    useEffect(() {
      loadFileDiff(currentIndex.value);
      return null;
    }, []);

    final currentFile = files[currentIndex.value];
    final statusColor = _getStatusColor(categoryColor);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentFile,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$category (${currentIndex.value + 1}/${files.length})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          // Previous button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            tooltip: 'Previous file',
            onPressed: currentIndex.value > 0 ? goToPrevious : null,
          ),
          // Next button
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            tooltip: 'Next file',
            onPressed: currentIndex.value < files.length - 1 ? goToNext : null,
          ),
          // Discard changes (only for modified/added files)
          if (category != 'Deleted' && category != 'Untracked')
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Discard changes',
              onPressed: discardChanges,
            ),
        ],
      ),
      body: Column(
        children: [
          // File indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: statusColor.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    currentFile,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Diff content
          Expanded(
            child: isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : DiffViewer(diff: fileDiff.value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
