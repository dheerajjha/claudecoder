import 'package:flutter/material.dart';

import '../models/file_tree_node.dart';

typedef FileTapCallback = void Function(FileTreeNode node);
typedef DirectoryTapCallback = bool Function(FileTreeNode node);
typedef NodeSubtitleBuilder = String? Function(FileTreeNode node);

class FileTreeView extends StatelessWidget {
  const FileTreeView({
    super.key,
    required this.nodes,
    required this.expandedNodeIds,
    required this.onToggleNode,
    this.onFileTap,
    this.onDirectoryTap,
    this.emptyLabel = 'No items found',
    this.searchQuery = '',
    this.showFileSize = false,
    this.subtitleBuilder,
  });

  final List<FileTreeNode> nodes;
  final Set<String> expandedNodeIds;
  final ValueChanged<String> onToggleNode;
  final FileTapCallback? onFileTap;
  final DirectoryTapCallback? onDirectoryTap;
  final String emptyLabel;
  final String searchQuery;
  final bool showFileSize;
  final NodeSubtitleBuilder? subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterNodes(nodes, searchQuery);
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: filtered.map((node) => _buildNode(context, node, 0)).toList(),
    );
  }

  Widget _buildNode(BuildContext context, FileTreeNode node, int depth) {
    final isExpanded = expandedNodeIds.contains(node.id);
    final indent = 12.0 + depth * 16.0;
    final subtitle = subtitleBuilder?.call(node);

    if (node.isDirectory) {
      final hasChildren = node.children.isNotEmpty;
      final icon = Icon(
        isExpanded ? Icons.folder_open : Icons.folder,
        color: Theme.of(context).colorScheme.primary,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.only(left: indent, right: 16),
            leading: icon,
            title: Text(node.name),
            subtitle: subtitle != null ? Text(subtitle) : null,
            trailing: hasChildren
                ? Icon(isExpanded ? Icons.expand_less : Icons.expand_more)
                : const Icon(Icons.chevron_right),
            onTap: () {
              final handled = onDirectoryTap?.call(node) ?? false;
              if (!handled && hasChildren) {
                onToggleNode(node.id);
              }
            },
          ),
          if (hasChildren && isExpanded)
            ...node.children
                .map((child) => _buildNode(context, child, depth + 1))
                .toList(),
        ],
      );
    }

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: indent, right: 16),
      leading: Icon(
        Icons.insert_drive_file,
        color: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(node.name),
      subtitle: subtitle != null
          ? Text(subtitle)
          : (showFileSize && node.size != null
                ? Text(_formatFileSize(node.size!))
                : null),
      onTap: () => onFileTap?.call(node),
    );
  }
}

List<FileTreeNode> _filterNodes(List<FileTreeNode> nodes, String query) {
  if (query.isEmpty) return nodes;

  final lowerQuery = query.toLowerCase();

  FileTreeNode? filterNode(FileTreeNode node) {
    final matchesSelf = node.name.toLowerCase().contains(lowerQuery);
    final filteredChildren = node.children
        .map(filterNode)
        .whereType<FileTreeNode>()
        .toList(growable: false);

    if (matchesSelf || filteredChildren.isNotEmpty) {
      return node.copyWith(children: filteredChildren);
    }

    return null;
  }

  return nodes
      .map(filterNode)
      .whereType<FileTreeNode>()
      .toList(growable: false);
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
