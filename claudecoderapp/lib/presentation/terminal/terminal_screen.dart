import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:gap/gap.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/providers/providers.dart';

class TerminalScreen extends HookConsumerWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);

    final terminal = useMemoized(() => Terminal(maxLines: 10000));
    final webSocketChannel = useState<WebSocketChannel?>(null);
    final webSocketSubscription = useState<StreamSubscription?>(null);
    final isConnected = useState(false);
    final isConnecting = useState(false);

    // Hidden TextField for capturing backspace on iOS
    final textFieldController = useTextEditingController();
    final textFieldFocus = useFocusNode();
    final lastTextValue = useState('');

    // Listen to focus changes
    useEffect(() {
      void onFocusChange() {
        print('🔍 TextField focus changed: ${textFieldFocus.hasFocus ? "FOCUSED" : "UNFOCUSED"}');
      }

      textFieldFocus.addListener(onFocusChange);
      return () => textFieldFocus.removeListener(onFocusChange);
    }, [textFieldFocus]);

    // Send data to terminal
    void sendToTerminal(String data) {
      if (webSocketChannel.value != null && isConnected.value) {
        try {
          final message = jsonEncode({'type': 'input', 'data': data});
          webSocketChannel.value!.sink.add(message);
        } catch (e) {
          terminal.write('\r\n\x1b[31mError sending data: $e\x1b[0m\r\n');
        }
      }
    }

    // Handle WebSocket messages
    void handleWebSocketMessage(dynamic message) {
      try {
        final data = jsonDecode(message);
        switch (data['type']) {
          case 'output':
            terminal.write(data['data']);
            break;
          case 'error':
            terminal.write('\r\n\x1b[31mError: ${data['message']}\x1b[0m\r\n');
            break;
        }
      } catch (error) {
        terminal.write('\r\n\x1b[31mMessage parse error: $error\x1b[0m\r\n');
      }
    }

    // Connect to backend
    Future<void> connectToBackend() async {
      if (isConnecting.value || selectedProject == null) return;

      isConnecting.value = true;

      try {
        final apiService = ref.read(apiServiceProvider);
        final storage = ref.read(storageServiceProvider);

        final config = await apiService.getConfig();
        final token = await storage.getToken();
        final wsUrl = config['wsUrl'] ?? 'ws://localhost:3001';

        // Connect to shell endpoint
        final uri = Uri.parse('$wsUrl/shell?token=$token');
        webSocketChannel.value = WebSocketChannel.connect(uri);

        // Send init message
        final initMessage = jsonEncode({
          'type': 'init',
          'projectPath': selectedProject.fullPath,
          'sessionId': null,
          'hasSession': false,
          'provider': 'plain-shell',
          'cols': terminal.viewWidth,
          'rows': terminal.viewHeight,
          'isPlainShell': true,
        });
        webSocketChannel.value!.sink.add(initMessage);

        // Listen to messages
        webSocketSubscription.value = webSocketChannel.value!.stream.listen(
          handleWebSocketMessage,
          onError: (error) {
            terminal.write('\r\n\x1b[31mWebSocket error: $error\x1b[0m\r\n');
            isConnected.value = false;
            isConnecting.value = false;
          },
          onDone: () {
            terminal.write('\r\n\x1b[33mConnection closed\x1b[0m\r\n');
            isConnected.value = false;
            isConnecting.value = false;
          },
        );

        isConnected.value = true;
        isConnecting.value = false;
      } catch (error) {
        terminal.write('\r\n\x1b[31mConnection failed: $error\x1b[0m\r\n');
        isConnecting.value = false;
      }
    }

    // Cleanup
    void cleanup() {
      webSocketSubscription.value?.cancel();
      webSocketChannel.value?.sink.close();
    }

    // Restart connection
    void restart() {
      cleanup();
      connectToBackend();
    }

    // Auto-connect when project is available
    useEffect(() {
      if (selectedProject != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          connectToBackend();
        });
      }

      return cleanup;
    }, [selectedProject]);

    // Set up terminal handlers - DISABLE onOutput, we'll use hidden TextField instead
    useEffect(() {
      // Disable terminal's own keyboard input - hidden TextField handles ALL input
      terminal.onOutput = null;

      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        if (webSocketChannel.value != null && isConnected.value) {
          try {
            webSocketChannel.value!.sink.add(
              jsonEncode({'type': 'resize', 'cols': width, 'rows': height}),
            );
          } catch (e) {
            // Ignore resize errors
          }
        }
      };

      return null;
    }, [isConnected.value]);

    if (selectedProject == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
              Gap(16),
              Text(
                'No project selected',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Gap(8),
              Text(
                'Please select a project to use the terminal',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Terminal', style: TextStyle(fontSize: 16)),
            Text(
              selectedProject.displayName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (!isConnected.value)
            IconButton(
              onPressed: restart,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reconnect',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main terminal UI
          Container(
              color: const Color(0xFF1E1E1E),
              child: Column(
                children: [
                  // Connection status bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isConnected.value
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color: isConnected.value
                              ? Colors.green
                              : Colors.orange,
                          size: 12,
                        ),
                        const Gap(8),
                        Text(
                          isConnected.value
                              ? 'Connected'
                              : (isConnecting.value
                                    ? 'Connecting...'
                                    : 'Disconnected'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Terminal display using xterm - read-only display (input via TextField below)
                  Expanded(
                    child: Stack(
                      children: [
                        // Terminal view that can be scrolled
                        GestureDetector(
                          // Only respond to taps, not long-presses (allow text selection)
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            print('👆 Tap detected - focusing TextField');
                            textFieldFocus.requestFocus();
                          },
                          // Allow long-press for text selection
                          onLongPressStart: null, // Don't intercept long-press
                          child: Container(
                            // Add bottom padding to account for TextField
                            padding: const EdgeInsets.only(bottom: 60),
                            color: const Color(0xFF1E1E1E),
                            child: TerminalView(
                              terminal,
                              theme: const TerminalTheme(
                          cursor: Color(0xFFFFFFFF),
                          selection: Color(0xFF264F78),
                          foreground: Color(0xFFD4D4D4),
                          background: Color(0xFF1E1E1E),
                          black: Color(0xFF000000),
                          red: Color(0xFFCD3131),
                          green: Color(0xFF0DBC79),
                          yellow: Color(0xFFE5E510),
                          blue: Color(0xFF2472C8),
                          magenta: Color(0xFFBC3FBC),
                          cyan: Color(0xFF11A8CD),
                          white: Color(0xFFE5E5E5),
                          brightBlack: Color(0xFF666666),
                          brightRed: Color(0xFFF14C4C),
                          brightGreen: Color(0xFF23D18B),
                          brightYellow: Color(0xFFF5F543),
                          brightBlue: Color(0xFF3B8EEA),
                          brightMagenta: Color(0xFFD670D6),
                          brightCyan: Color(0xFF29B8DB),
                          brightWhite: Color(0xFFFFFFFF),
                          searchHitBackground: Color(0xFFFFFF00),
                          searchHitBackgroundCurrent: Color(0xFFFF8C00),
                          searchHitForeground: Color(0xFF000000),
                        ),
                              autofocus: false, // Disabled - using TextField below
                              textScaler: TextScaler.noScaling,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ),
                        // Gesture overlay to detect scroll
                        Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerMove: (event) {
                            // Only dismiss keyboard if it's currently visible
                            if (event.delta.dy.abs() > 3 && textFieldFocus.hasFocus) {
                              print('📜 Scroll detected (dy: ${event.delta.dy}) - dismissing keyboard');
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TextField to capture ALL keyboard input including backspace
            // Positioned at bottom as a visible input field
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black87,
                child: TextField(
                  controller: textFieldController,
                  focusNode: textFieldFocus,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableInteractiveSelection: true, // Enable copy/paste
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  scrollPhysics: const BouncingScrollPhysics(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type commands here...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (newValue) {
                    final oldValue = lastTextValue.value;
                    print('✏️  TextField changed: "$oldValue" → "$newValue"');

                    if (newValue.length < oldValue.length) {
                      // Backspace detected
                      final numDeleted = oldValue.length - newValue.length;
                      print('⌫ Backspace! Deleted $numDeleted character(s)');
                      for (int i = 0; i < numDeleted; i++) {
                        sendToTerminal('\x7f');
                      }
                    } else if (newValue.length > oldValue.length) {
                      // Characters added (typed or pasted)
                      final added = newValue.substring(oldValue.length);
                      if (added.length > 1) {
                        print('📋 Paste detected: "$added" (${added.length} chars)');
                      } else {
                        print('➕ Character typed: "$added"');
                      }
                      for (int i = 0; i < added.length; i++) {
                        sendToTerminal(added[i]);
                      }
                    }

                    lastTextValue.value = newValue;
                  },
                  onSubmitted: (value) {
                    print('↩️  Enter pressed with value: "$value"');
                    sendToTerminal('\n');
                    textFieldController.clear();
                    lastTextValue.value = '';
                    textFieldFocus.requestFocus();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
