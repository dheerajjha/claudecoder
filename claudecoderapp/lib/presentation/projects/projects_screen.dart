import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/providers/providers.dart';
import '../../data/models/project.dart';
import '../../data/models/session.dart';

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
        onPressed: () {
          // TODO: Implement create project dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create project coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }
}

class SessionTile extends ConsumerWidget {
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
