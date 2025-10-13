import 'dart:async';

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
    state = state.copyWith(isLoadingHistory: true);
    try {
      final messages = await _apiService.getMessages(project.name, sessionId);
      state = state.copyWith(
        messages: messages,
        isLoadingHistory: false,
        activeSessionId: sessionId,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    await _connect();

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now().toIso8601String(),
    );

    state = state.copyWith(messages: [...state.messages, userMessage]);

    final targetSessionId = state.activeSessionId ?? initialSessionId;

    _webSocketService.sendClaudeCommand(
      trimmed,
      projectPath: project.fullPath,
      sessionId: targetSessionId,
      resume: targetSessionId != null,
      skipPermissions: state.skipPermissions,
    );
  }

  void toggleSkipPermissions() {
    state = state.copyWith(skipPermissions: !state.skipPermissions);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _handleMessage(WebSocketMessage wsMessage) {
    if (wsMessage.type == 'claude-response') {
      _handleClaudeResponse(wsMessage);
    } else if (wsMessage.type == 'claude-complete') {
      _finalizeStreamingMessage();
      _ref.read(fileBrowserRefreshProvider.notifier).state++;
    } else if (wsMessage.type == 'session-created') {
      final sessionId = wsMessage.sessionId;
      if (sessionId != null) {
        state = state.copyWith(activeSessionId: sessionId);
      }
    } else if (wsMessage.type == 'error') {
      state = state.copyWith(errorMessage: wsMessage.error);
    }
  }

  void _handleClaudeResponse(WebSocketMessage wsMessage) {
    String content = '';
    bool hasPermissionDenial = false;

    final responseData = wsMessage.data;
    if (responseData != null) {
      if (responseData['type'] == 'assistant') {
        final message = responseData['message'];
        if (message != null && message['content'] is List) {
          for (final block in message['content']) {
            if (block['type'] == 'text') {
              content += block['text']?.toString() ?? '';
            }
          }
        }
      }

      if (responseData['type'] == 'user') {
        final message = responseData['message'];
        if (message != null && message['content'] is List) {
          for (final block in message['content']) {
            if (block['type'] == 'tool_result' && block['is_error'] == true) {
              final errorContent = block['content']?.toString() ?? '';
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

    if (hasPermissionDenial) {
      final warning = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content:
            '⚠️ **Permission Required**\n\nI don\'t have the required permissions to complete this action. Enable permissions by tapping the lock icon.',
        timestamp: DateTime.now().toIso8601String(),
        isStreaming: false,
      );
      state = state.copyWith(messages: [...state.messages, warning]);
    }

    if (content.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    if (messages.isNotEmpty &&
        messages.last.role == 'assistant' &&
        messages.last.isStreaming) {
      final last = messages.removeLast();
      messages.add(last.copyWith(content: last.content + content));
    } else {
      messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: 'assistant',
          content: content,
          timestamp: DateTime.now().toIso8601String(),
          isStreaming: true,
        ),
      );
    }

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
