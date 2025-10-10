# Claude Coder Flutter App

A minimal Flutter client for the Claude Code UI backend.

## Features

- ✅ JWT Authentication
- ✅ Project & Session Management
- ✅ Real-time Chat with Claude via WebSocket
- ✅ File Explorer
- ✅ Clean Material Design 3 UI
- ✅ Dark/Light Theme Support

## Prerequisites

1. **Backend Server Running**
   ```bash
   cd ../claudecodeui
   npm install
   npm run server
   ```
   The server should be running on `http://localhost:3001`

2. **User Account Setup**
   - First time: Navigate to `http://localhost:3001` in browser
   - Create your account (this becomes your login for the Flutter app)
   - Or use the web interface to register a user

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on iOS Simulator
flutter run -d "iPhone 16 Pro"

# Run on Android Emulator
flutter run -d emulator-5554

# Run on Chrome (for testing)
flutter run -d chrome
```

## Login Credentials

Use the same username/password you created in the web interface.

If you haven't set up a user yet:
1. Start the backend server
2. Open `http://localhost:3001` in your browser
3. Register a new user
4. Use those credentials in the Flutter app

## Project Structure

```
lib/
├── core/
│   ├── constants/     # API endpoints
│   ├── providers/     # Riverpod state management
│   └── router/        # Navigation
├── data/
│   ├── models/        # Data models (Freezed)
│   ├── services/      # API & WebSocket services
│   └── repositories/
├── presentation/
│   ├── auth/         # Login screen
│   ├── projects/     # Projects list
│   ├── chat/         # Chat interface
│   └── files/        # File explorer
└── main.dart
```

## Configuration

The app connects to `http://localhost:3001` by default. To change this:

Edit `lib/core/constants/api_constants.dart`:
```dart
static const String defaultBaseUrl = 'http://your-server:port';
```

## Tech Stack

- **State Management:** Riverpod + Hooks
- **Code Generation:** Freezed + JSON Serializable
- **HTTP:** Dio
- **WebSocket:** web_socket_channel
- **Navigation:** go_router
- **Storage:** flutter_secure_storage
- **UI:** Material Design 3 + flutter_markdown

## Troubleshooting

### Authentication Error (401)
- Make sure the backend server is running
- Ensure you've created a user account via the web interface first
- Check that username/password are correct

### Cannot Connect to Server
- Verify backend is running: `curl http://localhost:3001/api/auth/status`
- Check iOS simulator can reach localhost (should work by default)
- For Android emulator, use `http://10.0.2.2:3001` instead

### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Next Steps

Optional enhancements you can add:
- [ ] Custom server URL in settings
- [ ] Voice input for chat
- [ ] File editing capabilities
- [ ] Offline mode with caching
- [ ] Push notifications
- [ ] Git operations integration

## Notes

- The app uses hot reload - save your changes and see them instantly
- WebSocket connection is established automatically on chat screen
- Tokens are stored securely using flutter_secure_storage
- The app supports both iOS and Android platforms
