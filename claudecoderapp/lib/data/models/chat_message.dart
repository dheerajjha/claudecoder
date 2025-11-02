import 'dart:convert';

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
    @Default([]) List<AttachedImage> images,
  }) = _ChatMessage;

  // Custom fromJson that mirrors web client's convertSessionMessages logic
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      // Handle JSONL entry format from backend (matches web client's approach)
      if (json.containsKey('message') && json['message'] is Map) {
        final message = json['message'] as Map<String, dynamic>;
        final role = (message['role'] ?? 'user').toString();
        String content = '';
        bool isToolUse = false;
        String? toolName;
        String? toolInput;

        // Extract content - handle both string and array formats (like web client)
        final messageContent = message['content'];
        if (messageContent is String) {
          content = messageContent;
        } else if (messageContent is List) {
          final textParts = <String>[];
          for (var part in messageContent) {
            if (part is Map) {
              if (part['type'] == 'text') {
                final text = (part['text'] ?? '').toString();
                if (text.isNotEmpty) {
                  textParts.add(text);
                }
              } else if (part['type'] == 'tool_use') {
                isToolUse = true;
                toolName = part['name']?.toString();
                // Format tool use like we do in _handleClaudeResponse
                final toolContent = '🔧 **Using Tool: ${part['name']}**\n\n```json\n${jsonEncode(part['input'] ?? {})}\n```';
                textParts.add(toolContent);
              } else if (part['type'] == 'tool_result') {
                // Format tool result
                final toolResultContent = part['content']?.toString() ?? '';
                final isError = part['is_error'] == true;
                final toolId = part['tool_use_id'] ?? 'unknown';

                final resultHeader = isError
                    ? '❌ **Tool Result (Error)** - ID: $toolId'
                    : '✅ **Tool Result** - ID: $toolId';

                textParts.add('$resultHeader\n\n```\n$toolResultContent\n```');
              }
            }
          }
          // Join with newlines like web client (line 1716 in ChatInterface.jsx)
          content = textParts.join('\n\n');
        }

        return ChatMessage(
          id:
              json['uuid']?.toString() ??
              json['sessionId']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
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
      return ChatMessage(
        id: json['id']?.toString() ?? '',
        role: json['role']?.toString() ?? 'user',
        content: json['content']?.toString() ?? '',
        timestamp: json['timestamp']?.toString(),
        metadata: json['metadata'] as Map<String, dynamic>?,
        isStreaming: json['isStreaming'] as bool? ?? false,
        isToolUse: json['isToolUse'] as bool?,
        toolName: json['toolName']?.toString(),
      );
    } catch (e) {
      // If parsing fails, return a placeholder message with error info
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'system',
        content: 'Error parsing message: $e',
        timestamp: DateTime.now().toIso8601String(),
        metadata: json,
        isStreaming: false,
      );
    }
  }
}

@freezed
class AttachedImage with _$AttachedImage {
  const factory AttachedImage({
    required String name,
    required String data, // Base64 encoded image data
    required String mimeType,
  }) = _AttachedImage;

  factory AttachedImage.fromJson(Map<String, dynamic> json) =>
      _$AttachedImageFromJson(json);
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
