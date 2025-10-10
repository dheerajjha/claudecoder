# Flutter App vs Web Client - Feature Parity

## ✅ Already Implemented (Core Features)

### Authentication
- [x] JWT-based login
- [x] Secure token storage
- [x] Auto-login on app start
- [x] Logout functionality

### Projects Management
- [x] List all projects
- [x] View project details
- [x] Display session count
- [x] Expandable project cards
- [x] Project path display

### Sessions
- [x] View all sessions per project
- [x] Display session metadata (title, date, message count)
- [x] Time-relative formatting ("2 hours ago")
- [x] Navigate to session chat
- [x] Support for both Claude & Cursor sessions

### Chat Interface
- [x] Real-time messaging via WebSocket
- [x] Send messages to Claude
- [x] Receive streaming responses
- [x] Markdown rendering
- [x] Auto-scroll to bottom
- [x] Session resume capability
- [x] Connection status indicator
- [x] Message history loading

### File Explorer
- [x] Browse project files
- [x] Directory tree view
- [x] File size display
- [x] Recursive folder navigation
- [x] File/folder icons

### UI/UX
- [x] Material Design 3
- [x] Dark/Light theme (system default)
- [x] Responsive layout
- [x] Loading states
- [x] Error handling
- [x] Pull-to-refresh

---

## 🚧 Web Features to Add

### High Priority

#### 1. Session Management
- [ ] Delete sessions
- [ ] Rename sessions
- [ ] Session search/filter
- [ ] Sort sessions (by date, name, etc.)

#### 2. Enhanced Chat
- [ ] Todo list display (from Claude responses)
- [ ] Tool call visualization
- [ ] Code blocks with syntax highlighting
- [ ] Copy code button
- [ ] Image upload support
- [ ] Voice input (using microphone)
- [ ] Stop/abort active session
- [ ] Retry failed messages

#### 3. File Operations
- [ ] View file content
- [ ] Edit files
- [ ] Create new files
- [ ] Delete files
- [ ] File search

#### 4. Git Integration
- [ ] View git status
- [ ] Stage/unstage files
- [ ] Commit changes
- [ ] Push/pull
- [ ] Branch management
- [ ] View diff
- [ ] Commit history

### Medium Priority

#### 5. Settings
- [ ] Custom server URL configuration
- [ ] Theme selection (light/dark/auto)
- [ ] Font size adjustment
- [ ] Auto-scroll toggle
- [ ] Notification preferences
- [ ] API key management

#### 6. Project Features
- [ ] Create new project
- [ ] Delete project
- [ ] Rename project
- [ ] Project favorites/pinning
- [ ] Search projects

#### 7. MCP (Model Context Protocol)
- [ ] MCP server configuration
- [ ] Tool listing
- [ ] Resource browser
- [ ] Prompt templates

#### 8. TaskMaster Integration
- [ ] Task creation
- [ ] Task list view
- [ ] Task status updates
- [ ] Task filtering

### Low Priority

#### 9. Advanced Features
- [ ] Offline mode
- [ ] Message caching
- [ ] Export chat history
- [ ] Share sessions
- [ ] Custom themes
- [ ] Keyboard shortcuts
- [ ] Split screen (chat + files)
- [ ] Multi-window support (iPad)

#### 10. Notifications
- [ ] Claude response notifications
- [ ] Task completion alerts
- [ ] Error notifications
- [ ] Background processing

---

## 📊 Current Feature Coverage

**Core Functionality:** ~80%
- ✅ Authentication
- ✅ Projects browsing
- ✅ Session viewing
- ✅ Basic chat
- ✅ File browsing

**Advanced Features:** ~20%
- ⚠️ Limited file operations
- ❌ No git integration
- ❌ No MCP support
- ❌ No TaskMaster
- ❌ Missing chat enhancements

---

## 🎯 Recommended Next Steps

### Phase 1: Chat Enhancements (1-2 days)
1. Add stop/abort session button
2. Implement code block syntax highlighting
3. Add copy code functionality
4. Display tool calls/todos
5. Image upload support

### Phase 2: Session Management (1 day)
1. Delete session functionality
2. Session search
3. Sort/filter options

### Phase 3: Settings & Configuration (1 day)
1. Settings screen
2. Custom server URL
3. Theme picker
4. Preferences storage

### Phase 4: Git Integration (2-3 days)
1. Git status view
2. Stage/commit UI
3. Branch management
4. Diff viewer

### Phase 5: File Operations (1-2 days)
1. File content viewer
2. Simple text editor
3. File creation/deletion

---

## 🔧 Technical Implementation Notes

### Code Syntax Highlighting
```yaml
dependencies:
  flutter_syntax_view: ^4.0.0
  # or
  highlight: ^0.7.0
```

### Image Upload
Already have `image_picker: ^1.1.2` in pubspec.yaml

### Git Operations
```yaml
dependencies:
  git: ^2.2.1
  # or use REST API calls to backend
```

### Settings Storage
Already have `shared_preferences: ^2.3.3`

### Notifications
```yaml
dependencies:
  flutter_local_notifications: ^17.2.3
```

---

## 📱 Platform-Specific Features

### iOS
- Haptic feedback on actions
- Native share sheet
- Face ID/Touch ID for auth
- Widgets (home screen)
- Siri shortcuts

### Android
- Material You theming
- Quick settings tile
- Widgets
- Share target

---

## 💡 Flutter-Specific Advantages

Things the Flutter app can do better than web:

1. **Offline Support** - Cache projects/sessions locally
2. **Native Performance** - Faster rendering, smoother animations
3. **Platform Integration** - Deep links, file system access
4. **Push Notifications** - Background alerts
5. **Biometric Auth** - Face ID, Touch ID, fingerprint
6. **Camera/Mic Access** - Better media input
7. **Background Processing** - Continue operations when minimized

---

## 🎨 UI/UX Improvements

Things to make the Flutter app feel native:

1. **Pull-to-refresh** - Already implemented ✅
2. **Swipe gestures** - Swipe to delete sessions
3. **Long-press menus** - Context actions
4. **Bottom sheets** - Native modals
5. **Hero animations** - Smooth transitions
6. **Platform-aware widgets** - Cupertino for iOS
7. **Adaptive layouts** - Phone, tablet, foldable

---

This document will be updated as features are implemented.
