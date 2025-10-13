import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../data/models/file_item.dart';

class FileViewerScreen extends HookConsumerWidget {
  final FileItem file;

  const FileViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);
    final contentController = useTextEditingController();
    final isLoading = useState(true);
    final isEditing = useState(false);
    final isSaving = useState(false);
    final hasChanges = useState(false);

    // Load file content
    useEffect(() {
      Future<void> loadContent() async {
        if (selectedProject == null) return;

        try {
          final apiService = ref.read(apiServiceProvider);
          final response = await apiService.getFileContent(
            selectedProject.name,
            file.path,
          );
          contentController.text = response['content'] ?? '';
          isLoading.value = false;
        } catch (e) {
          isLoading.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to load file: $e')));
          }
        }
      }

      loadContent();
      return null;
    }, []);

    // Track changes
    useEffect(() {
      void listener() {
        hasChanges.value = true;
      }

      contentController.addListener(listener);
      return () => contentController.removeListener(listener);
    }, []);

    Future<void> saveFile() async {
      if (selectedProject == null) return;

      isSaving.value = true;
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.saveFileContent(
          selectedProject.name,
          file.path,
          contentController.text,
        );

        hasChanges.value = false;
        isEditing.value = false;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File saved successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save file: $e')));
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(file.name, style: const TextStyle(fontSize: 16)),
        actions: [
          if (!isLoading.value && !isSaving.value)
            if (isEditing.value)
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: hasChanges.value ? saveFile : null,
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => isEditing.value = true,
              ),
        ],
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : isSaving.value
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving file...'),
                ],
              ),
            )
          : TextField(
              controller: contentController,
              readOnly: !isEditing.value,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: isEditing.value ? 'Edit file content...' : '',
              ),
              // Disable system context menu to prevent mobile errors
              contextMenuBuilder: (context, editableTextState) {
                return const SizedBox.shrink();
              },
            ),
    );
  }
}
