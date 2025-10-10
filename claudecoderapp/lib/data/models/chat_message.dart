import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String role, // 'user' or 'assistant'
    required String content,
    String? timestamp,
    Map<String, dynamic>? metadata,
    @Default(false) bool isStreaming,
    bool? isToolUse,
    String? toolName,
  }) = _ChatMessage;

  // Custom fromJson that mirrors web client's convertSessionMessages logic
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle JSONL entry format from backend (matches web client's approach)
    if (json.containsKey('message') && json['message'] is Map) {
      final message = json['message'] as Map<String, dynamic>;
      final role = message['role'] ?? 'user';
      String content = '';
      bool isToolUse = false;
      String? toolName;

      // Extract content - handle both string and array formats (like web client)
      final messageContent = message['content'];
      if (messageContent is String) {
        content = messageContent;
      } else if (messageContent is List) {
        final textParts = <String>[];
        for (var part in messageContent) {
          if (part is Map) {
            if (part['type'] == 'text') {
              textParts.add(part['text'] ?? '');
            } else if (part['type'] == 'tool_use') {
              isToolUse = true;
              toolName = part['name'];
            }
          }
        }
        content = textParts.join('');
      }

      return ChatMessage(
        id: json['uuid']?.toString() ?? json['sessionId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        role: role,
        content: content,
        timestamp: json['timestamp']?.toString(),
        metadata: json,
        isStreaming: false,
        isToolUse: isToolUse,
        toolName: toolName,
      );
    }

    // Standard format (for new messages created in-app)
    return _$ChatMessageFromJson(json);
  }
}

@freezed
class WebSocketMessage with _$WebSocketMessage {
  const factory WebSocketMessage({
    required String type,
    Map<String, dynamic>? data,
    String? sessionId,
    String? content,
    String? error,
  }) = _WebSocketMessage;

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) =>
      _$WebSocketMessageFromJson(json);
}
