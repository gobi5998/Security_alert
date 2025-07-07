class ApiConfig {
  // Base URL for the API
  static const String baseUrl =
      'https://5173-103-186-120-4.ngrok-free.app/api/';
  // Replace with your actual API base URL

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String userProfileEndpoint = '/auth/profile';
  static const String updateProfileEndpoint = '/auth/profile';

  // Security endpoints
  static const String securityAlertsEndpoint = '/alerts';
  static const String dashboardStatsEndpoint = '/dashboard/stats';
  static const String reportSecurityIssueEndpoint = '/reports';
  static const String threatHistoryEndpoint = '/alerts/history';

  // API Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout settings
  static const int connectTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds

  // Retry settings
  static const int maxRetries = 3;
  static const int retryDelay = 1000; // milliseconds

  // For development/testing purposes
  static const bool enableLogging = true;

  // Get full URL for an endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
