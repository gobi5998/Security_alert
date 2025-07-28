class ApiConfig {
  // Base URLs
  // static const String baseUrl =
  //     'https://6694dcc2db28.ngrok-free.app'; // Main server (working)
  static const String authBaseUrl =
      'https://0c94968f8ca9.ngrok-free.app'; // Auth server
  // TODO: Replace with your new ngrok URL after restarting ngrok
  static const String mainBaseUrl =
      'https://ea4b9a782d06.ngrok-free.app'; // Main server
  static const String fileUploadBaseUrl =
      'https://YOUR_NEW_NGROK_URL.ngrok-free.app'; // File upload server
  static const String reportsBaseUrl =
      'https://ea4b9a782d06.ngrok-free.app'; // Reports server

  // API Endpoints
  // Authentication endpoints
  static const String loginEndpoint = '/auth/login-user';
  static const String registerEndpoint = '/auth/create-user';
  static const String logoutEndpoint = '/auth/logout';
  static const String userProfileEndpoint = '/user/me';
  static const String updateProfileEndpoint = '/auth/profile';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';

  // Security endpoints
  static const String reportTypeEndpoint = '/report-type';
  static const String reportCategoryEndpoint = '/report-category';
  static const String securityAlertsEndpoint = '/alerts';
  static const String dashboardStatsEndpoint = '/dashboard/stats';
  static const String reportSecurityIssueEndpoint = '/reports';
  static const String malwareDropsEndpoint = '/reports';
  static const String threatHistoryEndpoint = '/alerts/history';

  // File upload endpoints
  static const String fileUploadEndpoint = '/file-upload';

  // Report endpoints
  static const String scamReportsEndpoint = '/reports/scam';
  static const String fraudReportsEndpoint = '/reports/fraud';
  static const String malwareReportsEndpoint = '/reports/malware';

  // User management endpoints
  static const String usersEndpoint = '/users';
  static const String userProfileUpdateEndpoint = '/user/profile';

  // API Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // File upload headers
  static const Map<String, String> fileUploadHeaders = {
    'Content-Type': 'multipart/form-data',
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
  // static String getUrl(String endpoint) {
  //   return '$baseUrl$endpoint';
  // }

  static String getAuthUrl(String endpoint) {
    return '$authBaseUrl$endpoint';
  }

  static String getMainUrl(String endpoint) {
    return '$mainBaseUrl$endpoint';
  }

  static String getFileUploadUrl(String endpoint) {
    return '$fileUploadBaseUrl$endpoint';
  }

  static String getReportsUrl(String endpoint) {
    return '$reportsBaseUrl$endpoint';
  }

  // Environment variables (for future use)
  static const String apiAuthService = 'http://localhost:3000';
  static const String apiCommunicationService = 'http://localhost:1509';
  static const String apiExternalService = 'http://localhost:9360';
  static const String apiReportsService = 'http://localhost:3996';
}
