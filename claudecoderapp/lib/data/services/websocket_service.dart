import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../models/chat_message.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();
  final Logger _logger = Logger();

  Stream<WebSocketMessage> get messages => _messageController.stream;
  bool get isConnected => _channel != null;

  Future<void> connect(String wsUrl, String token) async {
    try {
      _logger.d('Connecting to WebSocket: $wsUrl');

      // Close existing connection if any
      await disconnect();

      // Connect with authentication token
      final uri = Uri.parse('$wsUrl?token=$token');
      _channel = WebSocketChannel.connect(uri);

      // Listen to incoming messages
      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            final message = WebSocketMessage.fromJson(json);
            _messageController.add(message);
            _logger.d('WebSocket message received: ${message.type}');
          } catch (e) {
            _logger.e('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          _logger.e('WebSocket error: $error');
          _messageController.addError(error);
        },
        onDone: () {
          _logger.d('WebSocket connection closed');
          _channel = null;
        },
      );

      _logger.d('WebSocket connected successfully');
    } catch (e) {
      _logger.e('Failed to connect WebSocket: $e');
      throw Exception('WebSocket connection failed: $e');
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel == null) {
      throw Exception('WebSocket not connected');
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      _logger.d('WebSocket message sent: ${message['type']}');
    } catch (e) {
      _logger.e('Error sending WebSocket message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  void sendClaudeCommand(String command, {
    String? projectPath,
    String? sessionId,
    bool resume = false,
    bool skipPermissions = false,  // Default to ask for permissions (safer)
  }) {
    sendMessage({
      'type': 'claude-command',
      'command': command,
      'options': {
        if (projectPath != null) 'projectPath': projectPath,
        if (projectPath != null) 'cwd': projectPath,  // Add cwd for working directory
        if (sessionId != null) 'sessionId': sessionId,
        'resume': resume,
        // Add tools settings to control permissions
        'toolsSettings': {
          'skipPermissions': skipPermissions,
          'allowedTools': [],
          'disallowedTools': [],
        },
      },
    });
  }

  void sendCursorCommand(String command, {
    String? cwd,
    String? sessionId,
    bool resume = false,
    String? model,
  }) {
    sendMessage({
      'type': 'cursor-command',
      'command': command,
      'options': {
        if (cwd != null) 'cwd': cwd,
        if (sessionId != null) 'sessionId': sessionId,
        'resume': resume,
        if (model != null) 'model': model,
      },
    });
  }

  void abortSession(String sessionId, {String provider = 'claude'}) {
    sendMessage({
      'type': 'abort-session',
      'sessionId': sessionId,
      'provider': provider,
    });
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
      _logger.d('WebSocket disconnected');
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
