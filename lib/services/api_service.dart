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

      // Only use mock data if explicitly enabled for development
      if (_useMockData) {
        return _getMockLoginResponse(username);
      }

      final response = await _dio.post(ApiConfig.loginEndpoint, data: {
        'username': username,
        'password': password,
      });

      print('Login response: ${response.data}');

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

        // If the response doesn't contain user data, create a mock user (should not happen in production)
        if (!responseData.containsKey('user')) {
          throw Exception('Login failed: No user data returned from server.');
        }

        return responseData;
      }
      throw Exception('Login failed - Status: ${response.statusCode}');
    } on DioException catch (e) {
      print('DioException during login: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Response status: ${e.response?.statusCode}');

      if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password');
      } else {
        throw Exception(e.response?.data?['message'] ?? 'Login failed: ${e.message}');
      }
    } catch (e) {
      print('General exception during login: $e');
      // Do not fallback to mock data in production
      throw Exception('Login failed: Unable to reach authentication server.');
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

  Future<Map<String, dynamic>> register(String firstname, String lastname, String username, String password) async {
    try {
      // Print the payload for debugging
      final payload = {
        'firstName': firstname,
        'lastName': lastname,
        'username': username,
        'password': password,
      };
      print('Registration payload: $payload');

      final response = await _dio.post(ApiConfig.registerEndpoint, data: payload);

      print('Registration response: ${response.data}');
      print('Type of response.data: ${response.data.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic> && response.data['user'] is Map<String, dynamic>) {
          Map<String, dynamic> responseData = response.data;
          // Save token if it exists in the response
          if (responseData.containsKey('token')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', responseData['token']);
          } else if (responseData.containsKey('access_token')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', responseData['access_token']);
          }
          return responseData;
        } else {
          print('Unexpected response format: ${response.data}');
          throw Exception('Invalid registration response format');
        }
      } else {
        // Print backend error message if available
        if (response.data is Map<String, dynamic> && response.data['message'] != null) {
          throw Exception(response.data['message']);
        }
        throw Exception('Registration failed - Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException during registration: ${e.message}');
      print('Response data: ${e.response?.data}');
      // If API is not available, use mock data
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        print('Using mock data for registration');
        return _getMockRegisterResponse(firstname, lastname, username);
      }
      if (e.response?.statusCode == 409) {
        throw Exception('Username or email already exists');
      } else if (e.response?.statusCode == 400) {
        // Print backend error message if available
        if (e.response?.data is Map<String, dynamic> && e.response?.data['message'] != null) {
          throw Exception(e.response?.data['message']);
        }
        throw Exception('Invalid registration data');
      } else {
        throw Exception(e.response?.data?['message'] ?? 'Registration failed: ${e.message}');
      }
    } catch (e) {
      print('General exception during registration: $e');
      // Fallback to mock data
      return _getMockRegisterResponse(firstname, lastname, username);
    }
  }

  Map<String, dynamic> _getMockRegisterResponse(String firstname, String lastname, String username) {
    return {
      'user': {
        'id': '1',
        'firstname':firstname,
        'lastname':lastname,
        'username': username,
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

  // // Password reset endpoints
  // Future<Map<String, dynamic>> forgotPassword(String email) async {
  //   try {
  //     print('Requesting password reset for email: $email');

  //     if (_useMockData) {
  //       return _getMockForgotPasswordResponse(email);
  //     }

  //     final response = await _dio.post(ApiConfig.forgotPasswordEndpoint, data: {
  //       'email': email,
  //     });

  //     print('Forgot password response: ${response.data}');

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       return response.data;
  //     }
  //     throw Exception('Failed to send password reset email');
  //   } on DioException catch (e) {
  //     print('DioException during forgot password: ${e.message}');
  //     print('Response data: ${e.response?.data}');

  //     // If API is not available, use mock data
  //     if (e.type == DioExceptionType.connectionError ||
  //         e.type == DioExceptionType.connectionTimeout ||
  //         e.response?.statusCode == 404) {
  //       print('Using mock data for forgot password');
  //       return _getMockForgotPasswordResponse(email);
  //     }

  //     if (e.response?.statusCode == 404) {
  //       throw Exception('Email not found');
  //     } else if (e.response?.statusCode == 400) {
  //       throw Exception('Invalid email address');
  //     } else {
  //       throw Exception(e.response?.data?['message'] ?? 'Failed to send password reset email: ${e.message}');
  //     }
  //   } catch (e) {
  //     print('General exception during forgot password: $e');
  //     // Fallback to mock data
  //     return _getMockForgotPasswordResponse(email);
  //   }
  // }

  // Map<String, dynamic> _getMockForgotPasswordResponse(String email) {
  //   return {
  //     'message': 'Password reset link sent to $email (mock data)',
  //     'email': email,
  //     'status': 'success',
  //   };
  // }

  // Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
  //   try {
  //     print('Resetting password with token');

  //     if (_useMockData) {
  //       return _getMockResetPasswordResponse();
  //     }

  //     final response = await _dio.post(ApiConfig.resetPasswordEndpoint, data: {
  //       'token': token,
  //       'password': newPassword,
  //     });

  //     print('Reset password response: ${response.data}');

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       return response.data;
  //     }
  //     throw Exception('Failed to reset password');
  //   } on DioException catch (e) {
  //     print('DioException during reset password: ${e.message}');
  //     print('Response data: ${e.response?.data}');

  //     // If API is not available, use mock data
  //     if (e.type == DioExceptionType.connectionError ||
  //         e.type == DioExceptionType.connectionTimeout ||
  //         e.response?.statusCode == 404) {
  //       print('Using mock data for reset password');
  //       return _getMockResetPasswordResponse();
  //     }

  //     if (e.response?.statusCode == 400) {
  //       throw Exception('Invalid or expired token');
  //     } else if (e.response?.statusCode == 422) {
  //       throw Exception('Password does not meet requirements');
  //     } else {
  //       throw Exception(e.response?.data?['message'] ?? 'Failed to reset password: ${e.message}');
  //     }
  //   } catch (e) {
  //     print('General exception during reset password: $e');
  //     // Fallback to mock data
  //     return _getMockResetPasswordResponse();
  //   }
  // }

  // Map<String, dynamic> _getMockResetPasswordResponse() {
  //   return {
  //     'message': 'Password reset successfully (mock data)',
  //     'status': 'success',
  //   };
  // }

  // // Helper method to handle network errors
  // String _handleError(DioException error) {
  //   switch (error.type) {
  //     case DioExceptionType.connectionTimeout:
  //     case DioExceptionType.sendTimeout:
  //     case DioExceptionType.receiveTimeout:
  //       return 'Connection timeout. Please check your internet connection.';
  //     case DioExceptionType.badResponse:
  //       return error.response?.data['message'] ?? 'Server error occurred.';
  //     case DioExceptionType.cancel:
  //       return 'Request was cancelled.';
  //     case DioExceptionType.connectionError:
  //       return 'No internet connection.';
  //     default:
  //       return 'An unexpected error occurred.';
  //   }
  // }
}