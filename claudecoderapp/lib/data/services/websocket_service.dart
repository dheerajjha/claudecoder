import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();

  Stream<WebSocketMessage> get messages => _messageController.stream;
  bool get isConnected => _channel != null;

  Future<void> connect(String wsUrl, String token) async {
    try {
      print('📡 Connecting WebSocket: $wsUrl');

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
            print('📩 WS Received: ${message.type}');
          } catch (e) {
            print('❌ WS Parse Error: $e');
          }
        },
        onError: (error) {
          print('❌ WS Error: $error');
          _messageController.addError(error);
        },
        onDone: () {
          print('📡 WS Disconnected');
          _channel = null;
        },
      );

      print('✅ WebSocket connected');
    } catch (e) {
      print('❌ WS Connect failed: $e');
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
      print('📤 WS Sent: ${message['type']}');
    } catch (e) {
      print('❌ WS Send Error: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  void sendClaudeCommand(
    String command, {
    String? projectPath,
    String? sessionId,
    bool resume = false,
    bool skipPermissions = false, // Default to ask for permissions (safer)
    List<Map<String, dynamic>>? images,
  }) {
    sendMessage({
      'type': 'claude-command',
      'command': command,
      'options': {
        if (projectPath != null) 'projectPath': projectPath,
        if (projectPath != null)
          'cwd': projectPath, // Add cwd for working directory
        if (sessionId != null) 'sessionId': sessionId,
        'resume': resume,
        // Add tools settings to control permissions
        'toolsSettings': {
          'skipPermissions': skipPermissions,
          'allowedTools': [],
          'disallowedTools': [],
        },
        if (images != null && images.isNotEmpty) 'images': images,
      },
    });
  }

  void sendCursorCommand(
    String command, {
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
      print('📡 WebSocket disconnected');
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
