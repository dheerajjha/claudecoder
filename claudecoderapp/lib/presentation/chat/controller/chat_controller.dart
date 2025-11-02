import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/project.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/websocket_service.dart';

class ChatControllerParams {
  final Project project;
  final String? sessionId;

  const ChatControllerParams({required this.project, required this.sessionId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatControllerParams &&
          runtimeType == other.runtimeType &&
          project == other.project &&
          sessionId == other.sessionId;

  @override
  int get hashCode => Object.hash(project, sessionId);
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isConnecting;
  final bool isConnected;
  final bool isLoadingHistory;
  final bool skipPermissions;
  final String? activeSessionId;
  final String? errorMessage;

  const ChatState({
    required this.messages,
    required this.isConnecting,
    required this.isConnected,
    required this.isLoadingHistory,
    required this.skipPermissions,
    required this.activeSessionId,
    required this.errorMessage,
  });

  factory ChatState.initial({String? activeSessionId}) {
    return ChatState(
      messages: const [],
      isConnecting: false,
      isConnected: false,
      isLoadingHistory: false,
      skipPermissions: false,
      activeSessionId: activeSessionId,
      errorMessage: null,
    );
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnecting,
    bool? isConnected,
    bool? isLoadingHistory,
    bool? skipPermissions,
    String? activeSessionId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      skipPermissions: skipPermissions ?? this.skipPermissions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final chatControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatController, ChatState, ChatControllerParams>((ref, params) {
      final apiService = ref.watch(apiServiceProvider);
      final storageService = ref.watch(storageServiceProvider);
      final webSocketService = ref.watch(webSocketServiceProvider);

      return ChatController(
        ref,
        apiService: apiService,
        storageService: storageService,
        webSocketService: webSocketService,
        project: params.project,
        initialSessionId: params.sessionId,
      );
    });

class ChatController extends StateNotifier<ChatState> {
  ChatController(
    this._ref, {
    required ApiService apiService,
    required StorageService storageService,
    required WebSocketService webSocketService,
    required this.project,
    required this.initialSessionId,
  }) : _apiService = apiService,
       _storageService = storageService,
       _webSocketService = webSocketService,
       super(ChatState.initial(activeSessionId: initialSessionId)) {
    _initialize();
  }

  final Ref _ref;
  final ApiService _apiService;
  final StorageService _storageService;
  final WebSocketService _webSocketService;
  final Project project;
  final String? initialSessionId;

  StreamSubscription<WebSocketMessage>? _subscription;
  bool _isConnecting = false;

  Future<void> _initialize() async {
    await _connect();
    if (initialSessionId != null) {
      await _loadHistory(initialSessionId!);
    }
  }

  Future<void> _connect() async {
    if (_isConnecting || state.isConnected) return;
    _isConnecting = true;

    state = state.copyWith(isConnecting: true, isConnected: false);
    try {
      final config = await _apiService.getConfig();
      final token = await _storageService.getToken();
      final wsUrl = config['wsUrl'] ?? 'ws://localhost:3001';

      if (token == null) {
        throw Exception('Missing authentication token');
      }

      await _webSocketService.connect('$wsUrl/ws', token);

      _subscription?.cancel();
      _subscription = _webSocketService.messages.listen(
        _handleMessage,
        onError: (error) {
          state = state.copyWith(
            isConnected: false,
            errorMessage: error.toString(),
            isConnecting: false,
          );
        },
        onDone: () {
          state = state.copyWith(isConnected: false, isConnecting: false);
        },
      );

      state = state.copyWith(isConnected: true, isConnecting: false);
    } catch (error) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        errorMessage: error.toString(),
      );
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _loadHistory(String sessionId) async {
    print('📚 Chat: Loading history for session: $sessionId');
    state = state.copyWith(isLoadingHistory: true);
    try {
      final messages = await _apiService.getMessages(project.name, sessionId);
      print('📊 Chat: Loaded ${messages.length} messages from history');
      for (var i = 0; i < messages.length && i < 5; i++) {
        print('  - Message $i: role=${messages[i].role}, hasContent=${messages[i].content.isNotEmpty}, isToolUse=${messages[i].isToolUse}');
      }
      state = state.copyWith(
        messages: messages,
        isLoadingHistory: false,
        activeSessionId: sessionId,
      );
    } catch (error) {
      print('❌ Chat: Failed to load history: $error');
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> sendMessage(String content, {List<AttachedImage>? images}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty && (images == null || images.isEmpty)) return;

    print('📤 Chat: Sending message (${trimmed.length} chars, ${images?.length ?? 0} images)');

    await _connect();

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now().toIso8601String(),
      images: images ?? [],
    );

    state = state.copyWith(messages: [...state.messages, userMessage]);
    print('📊 Chat: User message added, total messages: ${state.messages.length}');

    final targetSessionId = state.activeSessionId ?? initialSessionId;

    // Convert images to the format expected by the backend
    List<Map<String, dynamic>>? imageData;
    if (images != null && images.isNotEmpty) {
      imageData = images.map((img) => {
        'name': img.name,
        'data': img.data,
        'mimeType': img.mimeType,
      }).toList();
      print('📸 Chat: Prepared ${imageData.length} images for sending');
    }

    _webSocketService.sendClaudeCommand(
      trimmed,
      projectPath: project.fullPath,
      sessionId: targetSessionId,
      resume: targetSessionId != null,
      skipPermissions: state.skipPermissions,
      images: imageData,
    );
  }

  void toggleSkipPermissions() {
    state = state.copyWith(skipPermissions: !state.skipPermissions);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _handleMessage(WebSocketMessage wsMessage) {
    print('💬 Chat: Processing WS message type: ${wsMessage.type}');

    if (wsMessage.type == 'claude-response') {
      _handleClaudeResponse(wsMessage);
    } else if (wsMessage.type == 'claude-complete') {
      print('✅ Chat: Claude response complete');
      _finalizeStreamingMessage();
      _ref.read(fileBrowserRefreshProvider.notifier).state++;
    } else if (wsMessage.type == 'session-created') {
      final sessionId = wsMessage.sessionId;
      if (sessionId != null) {
        print('🆔 Chat: Session created: $sessionId');
        state = state.copyWith(activeSessionId: sessionId);
      }
    } else if (wsMessage.type == 'error') {
      print('❌ Chat: Error message: ${wsMessage.error}');
      state = state.copyWith(errorMessage: wsMessage.error);
    } else {
      print('⚠️ Chat: Unknown message type: ${wsMessage.type}');
    }
  }

  void _handleClaudeResponse(WebSocketMessage wsMessage) {
    final responseData = wsMessage.data;
    if (responseData == null) {
      print('⚠️ Chat: claude-response has null data');
      return;
    }

    print('📝 Chat: Processing response data type: ${responseData['type']}');

    String content = '';
    String messageType = 'assistant';
    bool isToolUse = false;
    String? toolName;

    // Handle assistant messages
    if (responseData['type'] == 'assistant') {
      final message = responseData['message'];
      if (message != null && message['content'] is List) {
        for (final block in message['content']) {
          if (block['type'] == 'text') {
            content += block['text']?.toString() ?? '';
          } else if (block['type'] == 'tool_use') {
            isToolUse = true;
            toolName = block['name']?.toString();
            // Show tool use information
            final toolContent = '🔧 **Using Tool: ${block['name']}**\n\n```json\n${jsonEncode(block['input'])}\n```';
            content += (content.isNotEmpty ? '\n\n' : '') + toolContent;
          }
        }
      }
    }
    // Handle user/system messages (including tool results)
    else if (responseData['type'] == 'user' || responseData['type'] == 'system') {
      messageType = responseData['type'];
      final message = responseData['message'];
      if (message != null && message['content'] is List) {
        final parts = <String>[];
        for (final block in message['content']) {
          if (block['type'] == 'text') {
            parts.add(block['text']?.toString() ?? '');
          } else if (block['type'] == 'tool_result') {
            final toolResultContent = block['content']?.toString() ?? '';
            final isError = block['is_error'] == true;
            final toolId = block['tool_use_id'] ?? 'unknown';

            // Format tool result with clear indication
            final resultHeader = isError
                ? '❌ **Tool Result (Error)** - ID: $toolId'
                : '✅ **Tool Result** - ID: $toolId';

            parts.add('$resultHeader\n\n```\n$toolResultContent\n```');
          }
        }
        content = parts.join('\n\n');
      }
    }
    // Handle any other message types
    else {
      messageType = responseData['type'] ?? 'system';
      // Try to extract content from any message format
      if (responseData['content'] != null) {
        content = responseData['content'].toString();
      } else if (responseData['message'] != null) {
        final message = responseData['message'];
        if (message['content'] is String) {
          content = message['content'];
        } else if (message['content'] is List) {
          final parts = <String>[];
          for (final block in message['content']) {
            if (block['text'] != null) {
              parts.add(block['text'].toString());
            }
          }
          content = parts.join('\n');
        }
      }
    }

    // Always show messages, even if empty (to show tool use indicators, etc.)
    final messages = List<ChatMessage>.from(state.messages);

    // For assistant messages, support streaming
    if (messageType == 'assistant' && !isToolUse) {
      if (messages.isNotEmpty &&
          messages.last.role == 'assistant' &&
          messages.last.isStreaming) {
        print('➕ Chat: Appending to streaming message (${content.length} chars)');
        final last = messages.removeLast();
        messages.add(last.copyWith(content: last.content + content));
      } else if (content.isNotEmpty) {
        print('📨 Chat: New assistant message (${content.length} chars)');
        messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: messageType,
            content: content,
            timestamp: DateTime.now().toIso8601String(),
            isStreaming: true,
            isToolUse: isToolUse,
            toolName: toolName,
          ),
        );
      } else {
        print('⚠️ Chat: Empty assistant content, skipping');
      }
    } else {
      // For non-streaming messages (tool results, system messages, etc.)
      if (content.isNotEmpty) {
        print('📨 Chat: New $messageType message (${content.length} chars, toolUse: $isToolUse)');
        messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: messageType,
            content: content,
            timestamp: DateTime.now().toIso8601String(),
            isStreaming: false,
            isToolUse: isToolUse,
            toolName: toolName,
          ),
        );
      } else {
        print('⚠️ Chat: Empty $messageType content, skipping');
      }
    }

    print('📊 Chat: Total messages now: ${messages.length}');
    state = state.copyWith(messages: messages);
  }

  void _finalizeStreamingMessage() {
    if (state.messages.isEmpty) return;

    final updated = List<ChatMessage>.from(state.messages);
    final last = updated.last;
    if (last.isStreaming) {
      updated[updated.length - 1] = last.copyWith(isStreaming: false);
      state = state.copyWith(messages: updated);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}
