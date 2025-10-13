import 'package:flutter/foundation.dart';

@immutable
class FileTreeNode {
  final String id;
  final String name;
  final bool isDirectory;
  final int? size;
  final List<FileTreeNode> children;
  final Object? metadata;

  const FileTreeNode({
    required this.id,
    required this.name,
    required this.isDirectory,
    this.size,
    this.children = const [],
    this.metadata,
  });

  FileTreeNode copyWith({
    String? id,
    String? name,
    bool? isDirectory,
    int? size,
    List<FileTreeNode>? children,
    Object? metadata,
  }) {
    return FileTreeNode(
      id: id ?? this.id,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      children: children ?? this.children,
      metadata: metadata ?? this.metadata,
    );
  }
}
