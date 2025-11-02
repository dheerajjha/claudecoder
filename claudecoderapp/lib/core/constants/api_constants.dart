class ApiConstants {
  // Base URL - can be configured
  static const String defaultBaseUrl = 'http://98.70.88.219:3001';

  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String configEndpoint = '/api/config';
  static const String projectsEndpoint = '/api/projects';
  static const String createProjectEndpoint = '/api/projects/create';

  // WebSocket paths
  static const String chatWebSocketPath = '/ws';
  static const String shellWebSocketPath = '/shell';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String baseUrlKey = 'base_url';
  static const String usernameKey = 'username';

  // HTTP Headers
  static const String authHeader = 'Authorization';
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
}
