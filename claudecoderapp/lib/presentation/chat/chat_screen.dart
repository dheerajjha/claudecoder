import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

import '../../core/providers/providers.dart';
import '../../data/models/chat_message.dart';
import 'controller/chat_controller.dart';
import 'widgets/code_block.dart';
import 'widgets/file_browser.dart';
import '../git/git_screen.dart';
import '../terminal/terminal_screen.dart';

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

    void sendMessage() {
      final text = messageController.text.trim();
      if (text.isEmpty) return;
      messageController.clear();
      chatController.sendMessage(text);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
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

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy,
                  size: 16,
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const Gap(4),
                Text(
                  isUser ? 'You' : 'Claude',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const Gap(8),
            MarkdownBody(
              data: message.content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                code: TextStyle(
                  backgroundColor: Colors.black12,
                  fontFamily: 'monospace',
                ),
              ),
              builders: {'code': CodeBlockBuilder()},
            ),
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
