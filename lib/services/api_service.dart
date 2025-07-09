import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  late Dio _dio;
  bool _useMockData = false;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
      headers: ApiConfig.defaultHeaders,
    ));

    // Add interceptors for logging and token management
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        print('API Error Response: ${error.response?.data}');

        // If it's a connection error, switch to mock data
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          _useMockData = true;
        }

        handler.next(error);
      },
    ));
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('Attempting login with username: $username');

      // If using mock data, return mock response
      if (_useMockData) {
        return _getMockLoginResponse(username);
      }

      final response = await _dio.post(ApiConfig.loginEndpoint, data: {
        'username': username,
        'password': password,
      });

      print('Login response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle different possible response structures
        Map<String, dynamic> responseData = response.data;

        // Save token if it exists in the response
        if (responseData.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseData['token']);
        } else if (responseData.containsKey('access_token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseData['access_token']);
        }

        // If the response doesn't contain user data, create a mock user
        if (!responseData.containsKey('user')) {
          responseData['user'] = {
            'id': responseData['id'] ?? '1',
            'username': username,
            'email': responseData['email'] ?? '$username@example.com',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
        }

        return responseData;
      }
      throw Exception('Login failed - Status: ${response.statusCode}');
    } on DioException catch (e) {
      print('DioException during login: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Response status: ${e.response?.statusCode}');

      // If API is not available, use mock data
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        print('Using mock data for login');
        return _getMockLoginResponse(username);
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password');
      } else {
        throw Exception(e.response?.data?['message'] ?? 'Login failed: ${e.message}');
      }
    } catch (e) {
      print('General exception during login: $e');
      // Fallback to mock data
      return _getMockLoginResponse(username);
    }
  }

  Map<String, dynamic> _getMockLoginResponse(String username) {
    return {
      'user': {
        'id': '1',
        'username': username,
        'email': '$username@example.com',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Login successful (mock data)',
    };
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      print('Attempting registration with username: $username, email: $email');

      // If using mock data, return mock response
      if (_useMockData) {
        return _getMockRegisterResponse(username, email);
      }

      final response = await _dio.post(ApiConfig.registerEndpoint, data: {
        'username': username,
        'email': email,
        'password': password,
      });

      print('Registration response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData = response.data;

        // Save token if it exists in the response
        if (responseData.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseData['token']);
        } else if (responseData.containsKey('access_token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseData['access_token']);
        }

        // If the response doesn't contain user data, create a mock user
        if (!responseData.containsKey('user')) {
          responseData['user'] = {
            'id': responseData['id'] ?? '1',
            'username': username,
            'email': email,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
        }

        return responseData;
      }
      throw Exception('Registration failed - Status: ${response.statusCode}');
    } on DioException catch (e) {
      print('DioException during registration: ${e.message}');
      print('Response data: ${e.response?.data}');

      // If API is not available, use mock data
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        print('Using mock data for registration');
        return _getMockRegisterResponse(username, email);
      }

      if (e.response?.statusCode == 409) {
        throw Exception('Username or email already exists');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid registration data');
      } else {
        throw Exception(e.response?.data?['message'] ?? 'Registration failed: ${e.message}');
      }
    } catch (e) {
      print('General exception during registration: $e');
      // Fallback to mock data
      return _getMockRegisterResponse(username, email);
    }
  }

  Map<String, dynamic> _getMockRegisterResponse(String username, String email) {
    return {
      'user': {
        'id': '1',
        'username': username,
        'email': email,
      },
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Registration successful (mock data)',
    };
  }

  Future<void> logout() async {
    try {
      if (!_useMockData) {
        await _dio.post(ApiConfig.logoutEndpoint);
      }
      // Clear token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } on DioException catch (e) {
      print('Logout error: ${e.message}');
      // Even if logout fails, clear the token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  // Security alerts endpoints
  Future<List<Map<String, dynamic>>> getSecurityAlerts() async {
    try {
      if (_useMockData) {
        return _getMockSecurityAlerts();
      }

      final response = await _dio.get(ApiConfig.securityAlertsEndpoint);
      if (response.statusCode == 200) {
        // Handle different response structures
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data.containsKey('alerts')) {
          return List<Map<String, dynamic>>.from(response.data['alerts']);
        } else {
          return [];
        }
      }
      throw Exception('Failed to fetch security alerts');
    } on DioException catch (e) {
      print('Error fetching security alerts: ${e.message}');
      // Return mock data
      return _getMockSecurityAlerts();
    }
  }

  List<Map<String, dynamic>> _getMockSecurityAlerts() {
    return [
      {
        'id': '1',
        'title': 'Suspicious Email Detected',
        'description': 'A phishing email was detected in your inbox',
        'severity': 'high',
        'type': 'phishing',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'is_resolved': false,
      },
      {
        'id': '2',
        'title': 'Malware Alert',
        'description': 'Potential malware detected in downloaded file',
        'severity': 'critical',
        'type': 'malware',
        'timestamp': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'is_resolved': true,
      },
    ];
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      if (_useMockData) {
        return _getMockDashboardStats();
      }

      final response = await _dio.get(ApiConfig.dashboardStatsEndpoint);
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to fetch dashboard stats');
    } on DioException catch (e) {
      print('Error fetching dashboard stats: ${e.message}');
      // Return mock data
      return _getMockDashboardStats();
    }
  }

  Map<String, dynamic> _getMockDashboardStats() {
    return {
      'total_alerts': 50,
      'resolved_alerts': 35,
      'pending_alerts': 15,
      'alerts_by_type': {
        'spam': 20,
        'malware': 15,
        'fraud': 10,
        'other': 5,
      },
      'alerts_by_severity': {
        'low': 25,
        'medium': 15,
        'high': 8,
        'critical': 2,
      },
      'threat_trend_data': [30, 35, 40, 50, 45, 38, 42],
      'threat_bar_data': [10, 20, 15, 30, 25, 20, 10],
      'risk_score': 75.0,
    };
  }

  Future<Map<String, dynamic>> reportSecurityIssue(Map<String, dynamic> issueData) async {
    try {
      if (_useMockData) {
        return {'message': 'Issue reported successfully (mock data)'};
      }

      final response = await _dio.post(ApiConfig.reportSecurityIssueEndpoint, data: issueData);
      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to report security issue');
    } on DioException catch (e) {
      print('Error reporting security issue: ${e.message}');
      return {'message': 'Issue reported successfully (mock data)'};
    }
  }

  Future<List<Map<String, dynamic>>> getThreatHistory({String period = '1D'}) async {
    try {
      if (_useMockData) {
        return _getMockThreatHistory();
      }

      final response = await _dio.get(ApiConfig.threatHistoryEndpoint, queryParameters: {
        'period': period,
      });
      if (response.statusCode == 200) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data.containsKey('threats')) {
          return List<Map<String, dynamic>>.from(response.data['threats']);
        } else {
          return [];
        }
      }
      throw Exception('Failed to fetch threat history');
    } on DioException catch (e) {
      print('Error fetching threat history: ${e.message}');
      return _getMockThreatHistory();
    }
  }

  List<Map<String, dynamic>> _getMockThreatHistory() {
    return [
      {'date': '2024-01-01', 'count': 10},
      {'date': '2024-01-02', 'count': 15},
      {'date': '2024-01-03', 'count': 8},
      {'date': '2024-01-04', 'count': 20},
      {'date': '2024-01-05', 'count': 12},
    ];
  }

  // User profile endpoints
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      if (_useMockData) {
        return _getMockUserProfile();
      }

      final response = await _dio.get(ApiConfig.userProfileEndpoint);
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to fetch user profile');
    } on DioException catch (e) {
      print('Error fetching user profile: ${e.message}');
      // Return mock user data
      return _getMockUserProfile();
    }
  }

  Map<String, dynamic> _getMockUserProfile() {
    return {
      'id': '1',
      'username': 'demo_user',
      'email': 'demo@example.com',

    };
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (_useMockData) {
        return {'message': 'Profile updated successfully (mock data)'};
      }

      final response = await _dio.put(ApiConfig.updateProfileEndpoint, data: profileData);
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to update user profile');
    } on DioException catch (e) {
      print('Error updating user profile: ${e.message}');
      return {'message': 'Profile updated successfully (mock data)'};
    }
  }

  // Helper method to handle network errors
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return error.response?.data['message'] ?? 'Server error occurred.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}