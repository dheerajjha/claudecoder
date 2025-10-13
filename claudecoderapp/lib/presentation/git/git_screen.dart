import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../data/models/git_status.dart';
import 'controller/git_controller.dart';
import 'file_diff_screen.dart';

class GitScreen extends HookConsumerWidget {
  const GitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);

    if (project == null) {
      return const Scaffold(body: Center(child: Text('No project selected')));
    }

    final controllerProvider = gitControllerProvider(project);
    final gitState = ref.watch(controllerProvider);
    final controller = ref.watch(controllerProvider.notifier);

    final commitController = useTextEditingController(
      text: gitState.commitMessage,
    );

    useEffect(() {
      if (commitController.text != gitState.commitMessage) {
        commitController.text = gitState.commitMessage;
        commitController.selection = TextSelection.fromPosition(
          TextPosition(offset: commitController.text.length),
        );
      }
      return null;
    }, [gitState.commitMessage, commitController]);

    useEffect(() {
      void listener() => controller.setCommitMessage(commitController.text);
      commitController.addListener(listener);
      return () => commitController.removeListener(listener);
    }, [commitController, controller]);

    ref.listen<int>(gitRefreshProvider, (_, __) => controller.refresh());

    useEffect(() {
      if (gitState.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(gitState.errorMessage!)));
            controller.clearMessages();
          }
        });
      } else if (gitState.infoMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(gitState.infoMessage!),
                backgroundColor: Colors.green,
              ),
            );
            controller.clearMessages();
          }
        });
      }
      return null;
    }, [gitState.errorMessage, gitState.infoMessage, controller]);

    Future<void> openFileDiff(
      List<String> files,
      int index,
      String category,
      Color color,
    ) async {
      final shouldRefresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => FileDiffScreen(
            files: files,
            initialIndex: index,
            category: category,
            categoryColor: _colorToName(color),
          ),
        ),
      );

      if (shouldRefresh == true) {
        await controller.refresh();
      }
    }

    final status = gitState.status;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Git Changes', style: TextStyle(fontSize: 16)),
            if (status != null && status.error == null)
              Text(status.branch, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: gitState.isLoading ? null : controller.refresh,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (gitState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (status == null) {
            return const Center(child: Text('Unable to load git status'));
          }

          if (status.error != null) {
            final shouldShowInit = status.error!.toLowerCase().contains(
              'not a git repository',
            );
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.source_outlined,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const Gap(16),
                    Text(
                      status.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Gap(24),
                    if (shouldShowInit)
                      FilledButton.icon(
                        onPressed: gitState.isInitializing
                            ? null
                            : controller.initializeGit,
                        icon: gitState.isInitializing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(
                          gitState.isInitializing
                              ? 'Initializing...'
                              : 'Initialize Git',
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          if (!status.hasChanges) {
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
                  if (status.hasUnpushedCommits) ...[
                    const Gap(8),
                    Text(
                      '${status.ahead} unpushed commit${status.ahead == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const Gap(16),
                    FilledButton.icon(
                      onPressed: gitState.isPushing
                          ? null
                          : controller.pushToRemote,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      icon: gitState.isPushing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        gitState.isPushing ? 'Pushing...' : 'Push to Remote',
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          final sections = _buildSections(status);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: commitController,
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
                          '${gitState.selectedFiles.length} file${gitState.selectedFiles.length == 1 ? '' : 's'} selected',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        if (status.hasUnpushedCommits) ...[
                          FilledButton.icon(
                            onPressed: gitState.isPushing
                                ? null
                                : controller.pushToRemote,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            icon: gitState.isPushing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload, size: 18),
                            label: Text(
                              gitState.isPushing ? 'Pushing...' : 'Push',
                            ),
                          ),
                          const Gap(8),
                        ],
                        FilledButton.icon(
                          onPressed: _canCommit(gitState)
                              ? controller.commitChanges
                              : null,
                          icon: gitState.isCommitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: Text(
                            gitState.isCommitting ? 'Committing...' : 'Commit',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Files:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: controller.selectAll,
                      child: const Text(
                        'Select All',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const Gap(4),
                    TextButton(
                      onPressed: controller.deselectAll,
                      child: const Text(
                        'Deselect All',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: sections.expand((section) {
                    if (section.files.isEmpty) return <Widget>[];
                    final header = _SectionHeader(
                      title: '${section.title} (${section.files.length})',
                      color: section.color,
                    );
                    final items = section.files.asMap().entries.map((entry) {
                      final file = entry.value;
                      return _FileItemRow(
                        file: file,
                        statusLabel: section.statusLabel,
                        color: section.color,
                        isSelected: gitState.selectedFiles.contains(file),
                        onToggle: () => controller.toggleFileSelection(file),
                        onOpenDiff: () => openFileDiff(
                          section.files,
                          entry.key,
                          section.title,
                          section.color,
                        ),
                      );
                    });
                    return <Widget>[header, ...items, const Gap(8)];
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _canCommit(GitState state) {
    return state.commitMessage.trim().isNotEmpty &&
        state.selectedFiles.isNotEmpty &&
        !state.isCommitting;
  }

  String _colorToName(Color color) {
    if (color == Colors.orange) return 'orange';
    if (color == Colors.green) return 'green';
    if (color == Colors.red) return 'red';
    if (color == Colors.grey) return 'grey';
    return 'blue';
  }
}

class _GitSection {
  final String title;
  final List<String> files;
  final Color color;
  final String statusLabel;

  const _GitSection({
    required this.title,
    required this.files,
    required this.color,
    required this.statusLabel,
  });
}

List<_GitSection> _buildSections(GitStatus status) {
  return [
    _GitSection(
      title: 'Modified',
      files: status.modified,
      color: Colors.orange,
      statusLabel: 'M',
    ),
    _GitSection(
      title: 'Added',
      files: status.added,
      color: Colors.green,
      statusLabel: 'A',
    ),
    _GitSection(
      title: 'Deleted',
      files: status.deleted,
      color: Colors.red,
      statusLabel: 'D',
    ),
    _GitSection(
      title: 'Untracked',
      files: status.untracked,
      color: Colors.grey,
      statusLabel: '?',
    ),
  ];
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FileItemRow extends StatelessWidget {
  const _FileItemRow({
    required this.file,
    required this.statusLabel,
    required this.color,
    required this.isSelected,
    required this.onToggle,
    required this.onOpenDiff,
  });

  final String file;
  final String statusLabel;
  final Color color;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onOpenDiff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Checkbox(value: isSelected, onChanged: (_) => onToggle()),
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
              statusLabel,
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
              onTap: onOpenDiff,
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
            onPressed: onOpenDiff,
          ),
        ],
      ),
    );
  }
}
