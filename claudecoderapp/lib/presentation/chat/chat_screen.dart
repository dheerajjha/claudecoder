import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown/markdown.dart' as md;

import '../../core/providers/providers.dart';
import '../../data/models/chat_message.dart';
import 'controller/chat_controller.dart';
import 'widgets/code_block.dart';
import 'widgets/file_browser.dart';
import '../git/git_screen.dart';
import '../terminal/terminal_screen.dart';
import '../settings/settings_screen.dart';

class ChatScreen extends HookConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);
    final selectedSessionId = ref.watch(selectedSessionProvider);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Please select a project first')),
      );
    }

    final params = ChatControllerParams(
      project: project,
      sessionId: selectedSessionId,
    );

    final chatState = ref.watch(chatControllerProvider(params));
    final chatController = ref.watch(chatControllerProvider(params).notifier);

    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final currentTabIndex = useState(0);
    final attachedImages = useState<List<AttachedImage>>([]);
    final imagePicker = useMemoized(() => ImagePicker());
    final focusNode = useFocusNode();
    final lastBackPressTime = useRef<DateTime?>(null);

    useEffect(() {
      final error = chatState.errorMessage;
      if (error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
            chatController.clearError();
          }
        });
      }
      return null;
    }, [chatState.errorMessage, chatController]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      return null;
    }, [chatState.messages.length, scrollController]);

    Future<void> pickImages() async {
      try {
        final List<XFile> pickedFiles = await imagePicker.pickMultiImage();

        for (final file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final base64 = base64Encode(bytes);
          final mimeType = file.mimeType ?? 'image/jpeg';

          attachedImages.value = [
            ...attachedImages.value,
            AttachedImage(
              name: file.name,
              data: base64,
              mimeType: mimeType,
            ),
          ];
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick images: $e')),
          );
        }
      }
    }

    void removeImage(int index) {
      final updated = List<AttachedImage>.from(attachedImages.value);
      updated.removeAt(index);
      attachedImages.value = updated;
    }

    void sendMessage() {
      final text = messageController.text.trim();
      if (text.isEmpty && attachedImages.value.isEmpty) return;

      messageController.clear();
      final images = attachedImages.value;
      attachedImages.value = [];

      chatController.sendMessage(text, images: images.isEmpty ? null : images);
    }

    void handleBackButton() {
      // If keyboard is visible, dismiss it first
      if (focusNode.hasFocus) {
        focusNode.unfocus();
        lastBackPressTime.value = DateTime.now();
        return;
      }

      // Check if last back press was within 1 second
      final now = DateTime.now();
      if (lastBackPressTime.value != null &&
          now.difference(lastBackPressTime.value!).inSeconds < 1) {
        // Second tap within 1 second - pop the screen
        context.go('/');
      } else {
        // First tap or too long since last tap
        lastBackPressTime.value = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tap back again to exit chat'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: handleBackButton,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.displayName),
            Text(
              chatState.activeSessionId != null
                  ? 'Session: ${chatState.activeSessionId}'
                  : (selectedSessionId != null
                        ? 'Session: $selectedSessionId'
                        : 'New Session'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          Tooltip(
            message: chatState.skipPermissions
                ? 'Auto-approve: ON (risky)'
                : 'Ask permissions (safe)',
            child: IconButton(
              icon: Icon(
                chatState.skipPermissions ? Icons.lock_open : Icons.lock,
                color: chatState.skipPermissions ? Colors.orange : Colors.green,
              ),
              onPressed: chatController.toggleSkipPermissions,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.circle,
              size: 12,
              color: chatState.isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentTabIndex.value,
        children: [
          Column(
            children: [
              if (chatState.isConnecting)
                Container(
                  color: Colors.orange,
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.white),
                      Gap(8),
                      Text(
                        'Connecting...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: chatState.isLoadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : chatState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const Gap(16),
                            const Text('Start a conversation with Claude'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final reversedIndex =
                              chatState.messages.length - 1 - index;
                          final message = chatState.messages[reversedIndex];
                          return MessageBubble(message: message);
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image preview
                    if (attachedImages.value.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: attachedImages.value.length,
                          itemBuilder: (context, index) {
                            final image = attachedImages.value[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(image.data),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => removeImage(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    // Input row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: pickImages,
                          tooltip: 'Attach images',
                        ),
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        const Gap(8),
                        FilledButton(
                          onPressed: sendMessage,
                          child: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const FileBrowser(),
          const GitScreen(),
          const TerminalScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: currentTabIndex.value,
        onTap: (index) {
          currentTabIndex.value = index;
          if (index == 2) {
            ref.read(gitRefreshProvider.notifier).state++;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.source), label: 'Git'),
          BottomNavigationBarItem(
            icon: Icon(Icons.terminal),
            label: 'Terminal',
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isSystem = message.role == 'system';

    // Color scheme based on message type
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    if (isUser) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
      icon = Icons.person;
      label = 'You';
    } else if (isSystem) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      icon = Icons.info_outline;
      label = 'System';
    } else {
      backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
      textColor = Theme.of(context).colorScheme.onSecondaryContainer;
      icon = Icons.smart_toy;
      label = 'Claude';
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
                const Gap(4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const Gap(8),
            MarkdownBody(
              data: message.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: textColor),
                code: TextStyle(
                  backgroundColor: Colors.black12,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              builders: {'code': CodeBlockBuilder()},
            ),
            // Display attached images
            if (message.images.isNotEmpty) ...[
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.images.map((image) {
                  return GestureDetector(
                    onTap: () {
                      // Show full-size image in a dialog
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: InteractiveViewer(
                            child: Image.memory(
                              base64Decode(image.data),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(image.data),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String code = element.textContent;

    String? language;
    if (element.attributes['class'] != null) {
      final classAttr = element.attributes['class']!;
      if (classAttr.startsWith('language-')) {
        language = classAttr.substring('language-'.length);
      }
    }

    return CodeBlock(code: code, language: language);
  }
}
