import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/providers/providers.dart';
import '../../data/models/git_status.dart';
import 'file_diff_screen.dart';

class GitScreen extends HookConsumerWidget {
  const GitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);
    final gitStatus = useState<GitStatus?>(null);
    final isLoading = useState(false);
    final isInitializing = useState(false);
    final selectedFiles = useState<Set<String>>({});
    final commitMessage = useTextEditingController();
    final isCommitting = useState(false);
    final isPushing = useState(false);
    final hasCommitMessage = useState(false);

    // Listen to commit message changes
    useEffect(() {
      void listener() {
        hasCommitMessage.value = commitMessage.text.trim().isNotEmpty;
      }
      commitMessage.addListener(listener);
      return () => commitMessage.removeListener(listener);
    }, [commitMessage]);

    Future<void> loadGitStatus() async {
      if (selectedProject == null) return;

      isLoading.value = true;
      try {
        final apiService = ref.read(apiServiceProvider);
        final status = await apiService.getGitStatus(selectedProject.name);
        gitStatus.value = status;

        print('🔍 Git Status loaded:');
        print('  - Branch: ${status.branch}');
        print('  - Error: ${status.error}');
        print('  - Has changes: ${status.hasChanges}');
        print('  - Modified: ${status.modified.length}');
        print('  - Added: ${status.added.length}');
        print('  - Deleted: ${status.deleted.length}');
        print('  - Untracked: ${status.untracked.length}');

        if (status.error != null) {
          print('  - Error message: "${status.error}"');
          print('  - Contains "not a git repository" (lowercase): ${status.error!.toLowerCase().contains('not a git repository')}');
          print('  - Should show init button: ${status.error!.toLowerCase().contains('not a git repository')}');
        }

        // Auto-select all changed files
        if (status.error == null && status.hasChanges) {
          final allFiles = <String>{
            ...status.modified,
            ...status.added,
            ...status.deleted,
            ...status.untracked,
          };
          selectedFiles.value = allFiles;
          print('  - Auto-selected ${allFiles.length} files');
        }
      } catch (e) {
        print('❌ Error loading git status: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load git status: $e')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> initializeGit() async {
      if (selectedProject == null) return;

      isInitializing.value = true;
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.initGit(selectedProject.name);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Git initialized successfully')),
          );
        }

        // Reload git status
        await loadGitStatus();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to initialize git: $e')),
          );
        }
      } finally {
        isInitializing.value = false;
      }
    }

    Future<void> commitChanges() async {
      if (selectedProject == null || commitMessage.text.trim().isEmpty || selectedFiles.value.isEmpty) {
        return;
      }

      isCommitting.value = true;
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.commitChanges(
          projectName: selectedProject.name,
          message: commitMessage.text.trim(),
          files: selectedFiles.value.toList(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes committed successfully')),
          );
        }

        // Clear commit message and reload status
        commitMessage.clear();
        selectedFiles.value = {};
        await loadGitStatus();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to commit changes: $e')),
          );
        }
      } finally {
        isCommitting.value = false;
      }
    }

    Future<void> pushToRemote() async {
      if (selectedProject == null) return;

      isPushing.value = true;
      try {
        final apiService = ref.read(apiServiceProvider);
        final result = await apiService.pushToRemote(selectedProject.name);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['output'] ?? 'Pushed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload git status to update ahead count
        await loadGitStatus();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Push failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        isPushing.value = false;
      }
    }

    void toggleFileSelection(String filePath) {
      final newSet = Set<String>.from(selectedFiles.value);
      if (newSet.contains(filePath)) {
        newSet.remove(filePath);
      } else {
        newSet.add(filePath);
      }
      selectedFiles.value = newSet;
    }

    void selectAllFiles() {
      if (gitStatus.value == null) return;
      final allFiles = <String>{
        ...gitStatus.value!.modified,
        ...gitStatus.value!.added,
        ...gitStatus.value!.deleted,
        ...gitStatus.value!.untracked,
      };
      selectedFiles.value = allFiles;
    }

    void deselectAllFiles() {
      selectedFiles.value = {};
    }

    Future<void> openFileDiff(List<String> files, int index, String category, String color) async {
      final shouldRefresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => FileDiffScreen(
            files: files,
            initialIndex: index,
            category: category,
            categoryColor: color,
          ),
        ),
      );

      // Reload git status if changes were discarded
      if (shouldRefresh == true) {
        await loadGitStatus();
      }
    }


    // Watch git refresh trigger
    final gitRefreshTrigger = ref.watch(gitRefreshProvider);

    // Load git status on mount, when project changes, or when refresh is triggered
    useEffect(() {
      loadGitStatus();
      return null;
    }, [selectedProject, gitRefreshTrigger]);

    if (selectedProject == null) {
      return const Scaffold(
        body: Center(child: Text('No project selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Git Changes', style: TextStyle(fontSize: 16)),
            if (gitStatus.value != null && gitStatus.value!.error == null)
              Text(
                gitStatus.value!.branch,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: isLoading.value ? null : loadGitStatus,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          print('🎨 Building Git Screen UI:');
          print('  - isLoading: ${isLoading.value}');
          print('  - gitStatus: ${gitStatus.value}');
          print('  - gitStatus.error: ${gitStatus.value?.error}');

          if (isLoading.value) {
            print('  → Showing loading indicator');
            return const Center(child: CircularProgressIndicator());
          }

          if (gitStatus.value?.error != null) {
            print('  → Showing error state');
            print('  → Error message: "${gitStatus.value!.error}"');
            final shouldShowButton = gitStatus.value!.error!.toLowerCase().contains('not a git repository');
            print('  → Should show init button: $shouldShowButton');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.source_outlined, size: 64, color: Colors.orange),
                    const Gap(16),
                    Text(
                      gitStatus.value!.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Gap(24),
                    if (shouldShowButton) ...[
                      FilledButton.icon(
                        onPressed: isInitializing.value ? null : initializeGit,
                        icon: isInitializing.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add),
                        label: Text(isInitializing.value ? 'Initializing...' : 'Initialize Git'),
                      ),
                    ] else
                      Text('Button condition not met', style: TextStyle(color: Colors.red, fontSize: 10)),
                  ],
                ),
              ),
            );
          }

          print('  → Showing changes/no changes state');

          if (gitStatus.value == null || !gitStatus.value!.hasChanges) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Gap(16),
                  const Text('No changes'),
                  if (gitStatus.value?.hasUnpushedCommits == true) ...[
                    const Gap(8),
                    Text(
                      '${gitStatus.value!.ahead} unpushed commit${gitStatus.value!.ahead != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const Gap(16),
                    FilledButton.icon(
                      onPressed: isPushing.value ? null : pushToRemote,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      icon: isPushing.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(isPushing.value ? 'Pushing...' : 'Push to Remote'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
                      children: [
                        // Commit message area
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: commitMessage,
                                decoration: const InputDecoration(
                                  hintText: 'Commit message',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(12),
                                ),
                                maxLines: 2,
                              ),
                              const Gap(8),
                              Row(
                                children: [
                                  Text(
                                    '${selectedFiles.value.length} file${selectedFiles.value.length != 1 ? 's' : ''} selected',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const Spacer(),
                                  if (gitStatus.value?.hasUnpushedCommits == true) ...[
                                    FilledButton.icon(
                                      onPressed: isPushing.value ? null : pushToRemote,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      icon: isPushing.value
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.cloud_upload, size: 18),
                                      label: Text(isPushing.value ? 'Pushing...' : 'Push'),
                                    ),
                                    const Gap(8),
                                  ],
                                  FilledButton.icon(
                                    onPressed: !hasCommitMessage.value ||
                                              selectedFiles.value.isEmpty ||
                                              isCommitting.value
                                        ? null
                                        : commitChanges,
                                    icon: isCommitting.value
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.check, size: 18),
                                    label: Text(isCommitting.value ? 'Committing...' : 'Commit'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // File selection controls
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('Files:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              TextButton(
                                onPressed: selectAllFiles,
                                child: const Text('Select All', style: TextStyle(fontSize: 12)),
                              ),
                              const Gap(4),
                              TextButton(
                                onPressed: deselectAllFiles,
                                child: const Text('Deselect All', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        // File list
                        Expanded(
                          child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        // Modified files
                        if (gitStatus.value!.modified.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Modified',
                            gitStatus.value!.modified.length,
                            Colors.orange,
                          ),
                          ...gitStatus.value!.modified.asMap().entries.map(
                                (entry) => _buildFileItem(
                                  context,
                                  entry.value,
                                  'M',
                                  Colors.orange,
                                  selectedFiles.value.contains(entry.value),
                                  () => toggleFileSelection(entry.value),
                                  () => openFileDiff(
                                    gitStatus.value!.modified,
                                    entry.key,
                                    'Modified',
                                    'orange',
                                  ),
                                ),
                              ),
                          const Gap(8),
                        ],
                        // Added files
                        if (gitStatus.value!.added.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Added',
                            gitStatus.value!.added.length,
                            Colors.green,
                          ),
                          ...gitStatus.value!.added.asMap().entries.map(
                                (entry) => _buildFileItem(
                                  context,
                                  entry.value,
                                  'A',
                                  Colors.green,
                                  selectedFiles.value.contains(entry.value),
                                  () => toggleFileSelection(entry.value),
                                  () => openFileDiff(
                                    gitStatus.value!.added,
                                    entry.key,
                                    'Added',
                                    'green',
                                  ),
                                ),
                              ),
                          const Gap(8),
                        ],
                        // Deleted files
                        if (gitStatus.value!.deleted.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Deleted',
                            gitStatus.value!.deleted.length,
                            Colors.red,
                          ),
                          ...gitStatus.value!.deleted.asMap().entries.map(
                                (entry) => _buildFileItem(
                                  context,
                                  entry.value,
                                  'D',
                                  Colors.red,
                                  selectedFiles.value.contains(entry.value),
                                  () => toggleFileSelection(entry.value),
                                  () => openFileDiff(
                                    gitStatus.value!.deleted,
                                    entry.key,
                                    'Deleted',
                                    'red',
                                  ),
                                ),
                              ),
                          const Gap(8),
                        ],
                        // Untracked files
                        if (gitStatus.value!.untracked.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Untracked',
                            gitStatus.value!.untracked.length,
                            Colors.grey,
                          ),
                          ...gitStatus.value!.untracked.asMap().entries.map(
                                (entry) => _buildFileItem(
                                  context,
                                  entry.value,
                                  '?',
                                  Colors.grey,
                                  selectedFiles.value.contains(entry.value),
                                  () => toggleFileSelection(entry.value),
                                  () => openFileDiff(
                                    gitStatus.value!.untracked,
                                    entry.key,
                                    'Untracked',
                                    'grey',
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                          ),
                        ],
                      );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(8),
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    String file,
    String status,
    Color color,
    bool isSelected,
    VoidCallback onCheckboxTap,
    VoidCallback onFileTap,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) => onCheckboxTap(),
          ),
          const Gap(4),
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const Gap(8),
          Expanded(
            child: InkWell(
              onTap: onFileTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  file,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: onFileTap,
          ),
        ],
      ),
    );
  }
}
