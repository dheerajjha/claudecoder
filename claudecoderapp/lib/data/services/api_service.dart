import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/constants/api_constants.dart';
import '../models/chat_message.dart';
import '../models/file_item.dart';
import '../models/git_status.dart';
import '../models/project.dart';
import '../models/session.dart';
import '../models/user.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;
  final StorageService _storage;
  final Logger _logger = Logger();

  ApiService(this._storage, {String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? ApiConstants.defaultBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {ApiConstants.contentType: ApiConstants.applicationJson},
        ),
      ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers[ApiConstants.authHeader] = 'Bearer $token';
          }
          _logger.d('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  Future<T> _request<T>({
    required Future<Response<dynamic>> Function() send,
    required T Function(Response<dynamic>) parse,
    String fallbackError = 'Network error',
  }) async {
    try {
      final response = await send();
      return parse(response);
    } on DioException catch (e) {
      throw Exception(_extractError(e, fallbackError));
    }
  }

  String _extractError(DioException exception, String fallback) {
    final data = exception.response?.data;
    if (data is Map) {
      final details = data['details'] ?? data['error'] ?? data['message'];
      if (details != null) {
        return details.toString();
      }
    } else if (data != null) {
      return data.toString();
    }
    return exception.message ?? fallback;
  }

  // Auth endpoints
  Future<User> login(String username, String password) async {
    final user = await _request(
      send: () => _dio.post(
        ApiConstants.loginEndpoint,
        data: {'username': username, 'password': password},
      ),
      parse: (response) {
        if (response.statusCode == 200 && response.data['success'] == true) {
          return User(
            id: response.data['user']['id'],
            username: response.data['user']['username'],
            token: response.data['token'],
          );
        }
        throw Exception(response.data['error'] ?? 'Login failed');
      },
    );

    await _storage.saveToken(user.token);
    await _storage.saveUsername(user.username);
    return user;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  // Projects endpoints
  Future<List<Project>> getProjects() {
    return _request(
      send: () => _dio.get(ApiConstants.projectsEndpoint),
      parse: (response) {
        if (response.statusCode == 200 && response.data is List) {
          final data = response.data as List<dynamic>;
          return data.map((json) => Project.fromJson(json)).toList();
        }
        throw Exception('Failed to load projects');
      },
    );
  }

  Future<List<Session>> getSessions(
    String projectName, {
    int limit = 10,
    int offset = 0,
  }) {
    return _request(
      send: () => _dio.get(
        '/api/projects/$projectName/sessions',
        queryParameters: {'limit': limit, 'offset': offset},
      ),
      parse: (response) {
        if (response.statusCode == 200) {
          final List<dynamic> sessions = response.data['sessions'] ?? [];
          return sessions.map((json) => Session.fromJson(json)).toList();
        }
        throw Exception('Failed to load sessions');
      },
    );
  }

  Future<List<ChatMessage>> getMessages(
    String projectName,
    String sessionId, {
    int? limit,
    int offset = 0,
  }) {
    return _request(
      send: () => _dio.get(
        '/api/projects/$projectName/sessions/$sessionId/messages',
        queryParameters: {if (limit != null) 'limit': limit, 'offset': offset},
      ),
      parse: (response) {
        if (response.statusCode == 200) {
          final List<dynamic> messages = response.data['messages'] ?? [];
          return messages
              .map((json) => ChatMessage.fromJson(json))
              .where((msg) => msg.content.isNotEmpty)
              .toList();
        }
        throw Exception('Failed to load messages');
      },
    );
  }

  Future<Map<String, dynamic>> browseFilesystem({String? path}) {
    return _request(
      send: () => _dio.get(
        '/api/browse-filesystem',
        queryParameters: {if (path != null) 'path': path},
      ),
      parse: (response) {
        if (response.statusCode == 200 &&
            response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        throw Exception('Failed to browse filesystem');
      },
    );
  }

  Future<Map<String, dynamic>> createDirectory({
    required String parentPath,
    required String dirName,
  }) {
    return _request(
      send: () => _dio.post(
        '/api/create-directory',
        data: {'parentPath': parentPath, 'dirName': dirName},
      ),
      parse: (response) {
        if (response.statusCode == 200 &&
            response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        throw Exception('Failed to create directory');
      },
    );
  }

  Future<Project> createProject(String path) {
    return _request(
      send: () =>
          _dio.post(ApiConstants.createProjectEndpoint, data: {'path': path}),
      parse: (response) {
        if (response.statusCode == 200 && response.data['success'] == true) {
          return Project.fromJson(response.data['project']);
        }
        throw Exception(response.data['error'] ?? 'Failed to create project');
      },
    );
  }

  Future<void> deleteSession(String projectName, String sessionId) {
    return _request<void>(
      send: () => _dio.delete('/api/projects/$projectName/sessions/$sessionId'),
      parse: (response) {
        if (response.statusCode != 200) {
          throw Exception('Failed to delete session');
        }
      },
    );
  }

  Future<void> deleteProject(String projectName) {
    return _request<void>(
      send: () => _dio.delete('/api/projects/$projectName'),
      parse: (response) {
        if (response.statusCode != 200) {
          throw Exception('Failed to delete project');
        }
      },
    );
  }

  // File endpoints
  Future<List<FileItem>> getFiles(String projectName) {
    return _request(
      send: () => _dio.get('/api/projects/$projectName/files'),
      parse: (response) {
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          return data.map((json) => FileItem.fromJson(json)).toList();
        }
        throw Exception('Failed to load files');
      },
    );
  }

  Future<Map<String, dynamic>> getFileContent(
    String projectName,
    String filePath,
  ) {
    return _request(
      send: () => _dio.get(
        '/api/projects/$projectName/file',
        queryParameters: {'filePath': filePath},
      ),
      parse: (response) {
        if (response.statusCode == 200 &&
            response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        throw Exception('Failed to load file content');
      },
    );
  }

  Future<void> saveFileContent(
    String projectName,
    String filePath,
    String content,
  ) {
    return _request<void>(
      send: () => _dio.put(
        '/api/projects/$projectName/file',
        data: {'filePath': filePath, 'content': content},
      ),
      parse: (response) {
        if (response.statusCode != 200) {
          throw Exception('Failed to save file');
        }
      },
    );
  }

  // Config endpoint
  Future<Map<String, dynamic>> getConfig() {
    return _request(
      send: () => _dio.get(ApiConstants.configEndpoint),
      parse: (response) {
        if (response.statusCode == 200 &&
            response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        throw Exception('Failed to load config');
      },
    );
  }

  // Git endpoints
  Future<GitStatus> getGitStatus(String projectName) {
    return _request(
      send: () => _dio.get(
        '/api/git/status',
        queryParameters: {'project': projectName},
      ),
      parse: (response) {
        if (response.statusCode == 200) {
          return GitStatus.fromJson(response.data);
        }
        throw Exception('Failed to get git status');
      },
    );
  }

  Future<GitDiff> getGitDiff(String projectName, String filePath) {
    return _request(
      send: () => _dio.get(
        '/api/git/diff',
        queryParameters: {'project': projectName, 'file': filePath},
      ),
      parse: (response) {
        if (response.statusCode == 200) {
          return GitDiff.fromJson(response.data);
        }
        throw Exception('Failed to get git diff');
      },
    );
  }

  Future<void> commitChanges({
    required String projectName,
    required String message,
    required List<String> files,
  }) {
    return _request<void>(
      send: () => _dio.post(
        '/api/git/commit',
        data: {'project': projectName, 'message': message, 'files': files},
      ),
      parse: (response) {
        if (response.statusCode != 200) {
          throw Exception('Failed to commit changes');
        }
      },
    );
  }

  Future<void> discardChanges({
    required String projectName,
    required String filePath,
  }) {
    return _request<void>(
      send: () => _dio.post(
        '/api/git/discard',
        data: {'project': projectName, 'file': filePath},
      ),
      parse: (response) {
        if (response.statusCode != 200) {
          throw Exception('Failed to discard changes');
        }
      },
    );
  }

  Future<void> initGit(String projectName) {
    return _request<void>(
      send: () => _dio.post('/api/git/init', data: {'project': projectName}),
      parse: (response) {
        if (response.statusCode != 200) {
          throw Exception('Failed to initialize git');
        }
      },
    );
  }

  Future<Map<String, dynamic>> pushToRemote(String projectName) {
    return _request(
      send: () => _dio.post('/api/git/push', data: {'project': projectName}),
      parse: (response) {
        if (response.statusCode == 200 &&
            response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        throw Exception('Failed to push to remote');
      },
    );
  }
}
