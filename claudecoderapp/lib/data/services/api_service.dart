import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../models/session.dart';
import '../models/chat_message.dart';
import '../models/file_item.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;
  final StorageService _storage;
  final Logger _logger = Logger();

  ApiService(this._storage, {String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? ApiConstants.defaultBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            ApiConstants.contentType: ApiConstants.applicationJson,
          },
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers[ApiConstants.authHeader] = 'Bearer $token';
        }
        _logger.d('Request: ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        _logger.e('Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  // Auth endpoints
  Future<User> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = User(
          id: response.data['user']['id'],
          username: response.data['user']['username'],
          token: response.data['token'],
        );
        await _storage.saveToken(user.token);
        await _storage.saveUsername(user.username);
        return user;
      } else {
        throw Exception(response.data['error'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  // Projects endpoints
  Future<List<Project>> getProjects() async {
    try {
      final response = await _dio.get(ApiConstants.projectsEndpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Project.fromJson(json)).toList();
      }
      throw Exception('Failed to load projects');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<List<Session>> getSessions(String projectName, {int limit = 10, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/api/projects/$projectName/sessions',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> sessions = data['sessions'] ?? [];
        return sessions.map((json) => Session.fromJson(json)).toList();
      }
      throw Exception('Failed to load sessions');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<List<ChatMessage>> getMessages(
    String projectName,
    String sessionId, {
    int? limit,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/api/projects/$projectName/sessions/$sessionId/messages',
        queryParameters: {
          if (limit != null) 'limit': limit,
          'offset': offset,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> messages = data['messages'] ?? [];
        // Convert and filter out empty messages (like web client does)
        return messages
            .map((json) => ChatMessage.fromJson(json))
            .where((msg) => msg.content.isNotEmpty)
            .toList();
      }
      throw Exception('Failed to load messages');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> browseFilesystem({String? path}) async {
    try {
      final response = await _dio.get(
        '/api/browse-filesystem',
        queryParameters: {
          if (path != null) 'path': path,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to browse filesystem');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> createDirectory({
    required String parentPath,
    required String dirName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/create-directory',
        data: {
          'parentPath': parentPath,
          'dirName': dirName,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to create directory');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<Project> createProject(String path) async {
    try {
      final response = await _dio.post(
        ApiConstants.createProjectEndpoint,
        data: {'path': path},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Project.fromJson(response.data['project']);
      }
      throw Exception(response.data['error'] ?? 'Failed to create project');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> deleteSession(String projectName, String sessionId) async {
    try {
      final response = await _dio.delete(
        '/api/projects/$projectName/sessions/$sessionId',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete session');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> deleteProject(String projectName) async {
    try {
      final response = await _dio.delete('/api/projects/$projectName');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete project');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  // File endpoints
  Future<List<FileItem>> getFiles(String projectName) async {
    try {
      final response = await _dio.get('/api/projects/$projectName/files');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => FileItem.fromJson(json)).toList();
      }
      throw Exception('Failed to load files');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> getFileContent(String projectName, String filePath) async {
    try {
      final response = await _dio.get(
        '/api/projects/$projectName/file',
        queryParameters: {'filePath': filePath},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load file content');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  Future<void> saveFileContent(String projectName, String filePath, String content) async {
    try {
      final response = await _dio.put(
        '/api/projects/$projectName/file',
        data: {
          'filePath': filePath,
          'content': content,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to save file');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }

  // Config endpoint
  Future<Map<String, dynamic>> getConfig() async {
    try {
      final response = await _dio.get(ApiConstants.configEndpoint);
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load config');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Network error');
    }
  }
}
