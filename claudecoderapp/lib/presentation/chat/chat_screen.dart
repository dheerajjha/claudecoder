import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:markdown/markdown.dart' as md;
import '../../core/providers/providers.dart';
import '../../data/models/chat_message.dart';
import 'widgets/code_block.dart';
import 'widgets/file_browser.dart';
import '../git/git_screen.dart';

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
    final currentTabIndex = useState(0); // 0 = Chat, 1 = Files
    final skipPermissions = useState(false); // Permission toggle state
    final currentClaudeSessionId = useState<String?>(null); // Track current Claude session

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
            // Handle different message types from the backend
            if (wsMessage.type == 'claude-response') {
              // Extract text content from Claude's response structure
              String content = '';
              bool hasPermissionDenial = false;

              // Claude CLI sends: {type: 'claude-response', data: {type: 'assistant', message: {...}}}
              if (wsMessage.data != null) {
                final responseData = wsMessage.data!;

                // Check if this is an assistant message
                if (responseData['type'] == 'assistant') {
                  final message = responseData['message'];
                  if (message != null && message['content'] is List) {
                    // Extract text from content array
                    for (var contentBlock in message['content']) {
                      if (contentBlock['type'] == 'text') {
                        content += contentBlock['text'] ?? '';
                      }
                    }
                  }
                }

                // Check for permission denial in user/tool_result messages
                if (responseData['type'] == 'user') {
                  final message = responseData['message'];
                  if (message != null && message['content'] is List) {
                    for (var contentBlock in message['content']) {
                      if (contentBlock['type'] == 'tool_result' &&
                          contentBlock['is_error'] == true) {
                        final errorContent = contentBlock['content']?.toString() ?? '';
                        // Check if this is a permission error
                        if (errorContent.contains('requested permissions') ||
                            errorContent.contains("haven't granted it yet")) {
                          hasPermissionDenial = true;
                          break;
                        }
                      }
                    }
                  }
                }
              }

              // Show permission denial message
              if (hasPermissionDenial) {
                final errorMessage = ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  role: 'assistant',
                  content: '⚠️ **Permission Required**\n\nI don\'t have the required permissions to complete this action. Please enable permissions by tapping the lock icon (🔒) in the top right corner to unlock it (🔓).\n\nThis will allow me to modify files and execute commands.',
                  timestamp: DateTime.now().toIso8601String(),
                  isStreaming: false,
                );
                messages.value = [...messages.value, errorMessage];
              }

              if (content.isNotEmpty) {
                // Check if last message is from assistant and streaming
                if (messages.value.isNotEmpty &&
                    messages.value.last.role == 'assistant' &&
                    messages.value.last.isStreaming) {
                  // Append to existing message
                  final updatedMessages = [...messages.value];
                  final lastMessage = updatedMessages.last;
                  updatedMessages[updatedMessages.length - 1] = ChatMessage(
                    id: lastMessage.id,
                    role: 'assistant',
                    content: lastMessage.content + content,
                    timestamp: lastMessage.timestamp,
                    isStreaming: true,
                  );
                  messages.value = updatedMessages;
                } else {
                  // Create new assistant message
                  final chatMessage = ChatMessage(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    role: 'assistant',
                    content: content,
                    timestamp: DateTime.now().toIso8601String(),
                    isStreaming: true,
                  );
                  messages.value = [...messages.value, chatMessage];
                }
              }
            } else if (wsMessage.type == 'claude-complete') {
              // Mark last message as complete (stop streaming)
              if (messages.value.isNotEmpty && messages.value.last.isStreaming) {
                final updatedMessages = [...messages.value];
                final lastMessage = updatedMessages.last;
                updatedMessages[updatedMessages.length - 1] = ChatMessage(
                  id: lastMessage.id,
                  role: lastMessage.role,
                  content: lastMessage.content,
                  timestamp: lastMessage.timestamp,
                  isStreaming: false,
                );
                messages.value = updatedMessages;
              }

              // Trigger file browser refresh when Claude completes
              // This will show any new files created or modified
              ref.read(fileBrowserRefreshProvider.notifier).state++;
            } else if (wsMessage.type == 'session-created') {
              // New session created - capture the session ID
              // sessionId is at root level of WebSocketMessage, not in data
              final sessionId = wsMessage.sessionId;
              if (sessionId != null) {
                currentClaudeSessionId.value = sessionId;
                // Don't update global provider here - it would cause useEffect to re-run
                // and disconnect the WebSocket, causing messages to disappear
                print('✅ Session created and captured: $sessionId');
              }
            } else if (wsMessage.type == 'error') {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(wsMessage.error ?? 'Unknown error')),
                );
              }
            }

            // Auto-scroll to bottom (position 0 in reverse ListView)
            Future.delayed(const Duration(milliseconds: 100), () {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          });

          // Load existing messages if session is selected
          if (selectedProject != null && selectedSessionId != null) {
            isLoading.value = true;
            // Set the current session ID when resuming an existing session
            currentClaudeSessionId.value = selectedSessionId;
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
      // Use currentClaudeSessionId for session continuity within this chat
      final sessionToUse = currentClaudeSessionId.value ?? selectedSessionId;
      print('📤 Sending message with sessionId: $sessionToUse, resume: ${sessionToUse != null}');
      webSocketService.sendClaudeCommand(
        message,
        projectPath: selectedProject.fullPath,
        sessionId: sessionToUse,
        resume: sessionToUse != null,
        skipPermissions: skipPermissions.value,
      );

      // Auto-scroll to bottom (position 0 in reverse ListView)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
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
          // Permission toggle
          Tooltip(
            message: skipPermissions.value
                ? 'Auto-approve: ON (risky)'
                : 'Ask permissions (safe)',
            child: IconButton(
              icon: Icon(
                skipPermissions.value ? Icons.lock_open : Icons.lock,
                color: skipPermissions.value ? Colors.orange : Colors.green,
              ),
              onPressed: () {
                skipPermissions.value = !skipPermissions.value;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      skipPermissions.value
                          ? 'Auto-approve enabled - Claude can modify files without asking'
                          : 'Permissions required - Claude will ask before modifying files',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          if (isConnected.value)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.circle, color: Colors.green, size: 12),
            ),
        ],
      ),
      body: IndexedStack(
        index: currentTabIndex.value,
        children: [
          // Chat tab
          Column(
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
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.value.length,
                            itemBuilder: (context, index) {
                              // Reverse the index since we're using reverse: true
                              final reversedIndex = messages.value.length - 1 - index;
                              final message = messages.value[reversedIndex];
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

          // Files tab
          const FileBrowser(),

          // Git tab
          const GitScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex.value,
        onTap: (index) {
          currentTabIndex.value = index;
          // Trigger git refresh when switching to Git tab
          if (index == 2) {
            ref.read(gitRefreshProvider.notifier).state++;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.source),
            label: 'Git',
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
              builders: {
                'code': CodeBlockBuilder(),
              },
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

    // Extract language from code fence (e.g., ```dart, ```python)
    String? language;
    if (element.attributes['class'] != null) {
      // Class format is typically "language-dart" or "language-python"
      final classAttr = element.attributes['class']!;
      if (classAttr.startsWith('language-')) {
        language = classAttr.substring('language-'.length);
      }
    }

    return CodeBlock(
      code: code,
      language: language,
    );
  }
}
