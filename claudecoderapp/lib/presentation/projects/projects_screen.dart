import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/providers/providers.dart';
import '../../data/models/project.dart';
import '../../data/models/session.dart';
import 'widgets/directory_browser.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final selectedProject = ref.watch(selectedProjectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(projectsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Text('No projects found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final isSelected = selectedProject?.name == project.name;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ExpansionTile(
                  leading: Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    project.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    project.fullPath,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Chip(
                    label: Text(
                      '${project.sessions.length} sessions',
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onExpansionChanged: (expanded) {
                    if (expanded) {
                      ref.read(selectedProjectProvider.notifier).state = project;
                    }
                  },
                  children: [
                    if (project.sessions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No sessions found'),
                      )
                    else
                      ...project.sessions.map((session) => SessionTile(
                            session: session,
                            project: project,
                          )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('New Session'),
                        onPressed: () {
                          ref.read(selectedProjectProvider.notifier).state = project;
                          ref.read(selectedSessionProvider.notifier).state = null;
                          context.go('/chat');
                        },
                      ),
                    ),
                  ],
                ),
              );
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
                onPressed: () => ref.invalidate(projectsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewProjectDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _NewProjectDialog(ref: ref),
    );
  }
}

class _NewProjectDialog extends StatefulWidget {
  final WidgetRef ref;

  const _NewProjectDialog({required this.ref});

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  String? _selectedPath;
  bool _isCreating = false;

  void _onDirectorySelected(String path) {
    setState(() {
      _selectedPath = path;
    });
  }

  Future<void> _createProject() async {
    if (_selectedPath == null) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final apiService = widget.ref.read(apiServiceProvider);
      final project = await apiService.createProject(_selectedPath!);

      // Refresh projects list
      widget.ref.invalidate(projectsProvider);

      if (mounted) {
        Navigator.of(context).pop();

        // Set as selected project and navigate to chat
        widget.ref.read(selectedProjectProvider.notifier).state = project;
        widget.ref.read(selectedSessionProvider.notifier).state = null;
        context.go('/chat');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create project: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'New Project',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const Gap(6),
            const Text(
              'Browse server directories and select a folder to register as a project:',
              style: TextStyle(fontSize: 11),
            ),
            const Gap(12),

            // Directory browser
            Expanded(
              child: DirectoryBrowser(
                onDirectorySelected: _onDirectorySelected,
              ),
            ),

            const Gap(12),

            // Selected path display - compact
            if (_selectedPath != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const Gap(6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected:',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            _selectedPath!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),
            ],

            // Action buttons - compact
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
                const Gap(8),
                FilledButton(
                  onPressed: _selectedPath == null || _isCreating ? null : _createProject,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Project', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SessionTile extends ConsumerWidget{
  final Session session;
  final Project project;

  const SessionTile({
    super.key,
    required this.session,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        session.provider == 'cursor' ? Icons.mouse : Icons.chat,
        size: 20,
      ),
      title: Text(session.title ?? 'Session ${session.id}'),
      subtitle: Text(
        session.lastActivity != null
            ? timeago.format(DateTime.parse(session.lastActivity!))
            : (session.createdAt != null
                ? timeago.format(DateTime.parse(session.createdAt!))
                : 'No date'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: session.messageCount != null
          ? Chip(
              label: Text(
                '${session.messageCount}',
                style: const TextStyle(fontSize: 11),
              ),
              padding: EdgeInsets.zero,
            )
          : null,
      onTap: () {
        ref.read(selectedProjectProvider.notifier).state = project;
        ref.read(selectedSessionProvider.notifier).state = session.id;
        context.go('/chat');
      },
    );
  }
}
