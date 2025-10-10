import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gap/gap.dart';
import '../../core/providers/providers.dart';
import '../../data/models/chat_message.dart';

class ChatScreen extends HookConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);
    final selectedSessionId = ref.watch(selectedSessionProvider);
    final webSocketService = ref.watch(webSocketServiceProvider);

    final messages = useState<List<ChatMessage>>([]);
    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final isConnected = useState(false);
    final isLoading = useState(false);

    // Connect to WebSocket
    useEffect(() {
      Future<void> connect() async {
        final apiService = ref.read(apiServiceProvider);
        final storage = ref.read(storageServiceProvider);

        try {
          final config = await apiService.getConfig();
          final token = await storage.getToken();
          final wsUrl = config['wsUrl'] ?? 'ws://localhost:3001';

          await webSocketService.connect('$wsUrl/ws', token!);
          isConnected.value = true;

          // Listen to WebSocket messages
          webSocketService.messages.listen((wsMessage) {
            if (wsMessage.type == 'assistant-message' ||
                wsMessage.type == 'user-message') {
              final chatMessage = ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                role: wsMessage.type == 'user-message' ? 'user' : 'assistant',
                content: wsMessage.content ?? '',
                timestamp: DateTime.now().toIso8601String(),
              );
              messages.value = [...messages.value, chatMessage];

              // Auto-scroll to bottom
              Future.delayed(const Duration(milliseconds: 100), () {
                if (scrollController.hasClients) {
                  scrollController.animateTo(
                    scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            } else if (wsMessage.type == 'error') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(wsMessage.error ?? 'Unknown error')),
              );
            }
          });

          // Load existing messages if session is selected
          if (selectedProject != null && selectedSessionId != null) {
            isLoading.value = true;
            final existingMessages = await apiService.getMessages(
              selectedProject.name,
              selectedSessionId,
            );
            messages.value = existingMessages;
            isLoading.value = false;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect: $e')),
          );
        }
      }

      connect();

      return () {
        webSocketService.disconnect();
      };
    }, [selectedProject, selectedSessionId]);

    void sendMessage() {
      if (messageController.text.trim().isEmpty || selectedProject == null) {
        return;
      }

      final message = messageController.text.trim();
      messageController.clear();

      // Add user message to UI
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: message,
        timestamp: DateTime.now().toIso8601String(),
      );
      messages.value = [...messages.value, userMessage];

      // Send via WebSocket
      webSocketService.sendClaudeCommand(
        message,
        projectPath: selectedProject.fullPath,
        sessionId: selectedSessionId,
        resume: selectedSessionId != null,
      );

      // Auto-scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    if (selectedProject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: Text('Please select a project first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(selectedProject.displayName),
            Text(
              selectedSessionId != null ? 'Session: $selectedSessionId' : 'New Session',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (isConnected.value)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.circle, color: Colors.green, size: 12),
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          if (!isConnected.value)
            Container(
              color: Colors.orange,
              padding: const EdgeInsets.all(8),
              child: const Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.white),
                  Gap(8),
                  Text('Connecting...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : messages.value.isEmpty
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
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.value.length,
                        itemBuilder: (context, index) {
                          final message = messages.value[index];
                          return MessageBubble(message: message);
                        },
                      ),
          ),

          // Input area
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
            ),
          ],
        ),
      ),
    );
  }
}
