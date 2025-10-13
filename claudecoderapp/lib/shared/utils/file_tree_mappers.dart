import '../../data/models/file_item.dart';
import '../models/file_tree_node.dart';

FileTreeNode fileItemToNode(FileItem item) {
  return FileTreeNode(
    id: item.path,
    name: item.name,
    isDirectory: item.type == 'directory',
    size: item.size,
    metadata: item,
    children: item.children.map(fileItemToNode).toList(growable: false),
  );
}
