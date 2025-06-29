class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://685e7da87b57aebd2af9a21d.mockapi.io'; // Replace with your actual API base URL
  
  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String userProfileEndpoint = '/users/1'; // Mock user profile
  static const String updateProfileEndpoint = '/users/1';
  
  // Security endpoints
  static const String securityAlertsEndpoint = '/alerts';
  static const String dashboardStatsEndpoint = '/stats';
  static const String reportSecurityIssueEndpoint = '/reports';
  static const String threatHistoryEndpoint = '/threats';
  
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
  
  // Mock data endpoints (for development)
  static const String mockDataBaseUrl = 'https://jsonplaceholder.typicode.com';
  
  // Get full URL for an endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Get mock URL for development
  static String getMockUrl(String endpoint) {
    return '$mockDataBaseUrl$endpoint';
  }
} 