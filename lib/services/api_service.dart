import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:hive/hive.dart';
import '../models/scam_report_model.dart';

class ApiService {
  late Dio _dio;
  bool _useMockData = false;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
        headers: ApiConfig.defaultHeaders,
      ),
    );

    // Add interceptors for logging and token management
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => print(obj),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
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
      ),
    );
  }

  // Authentication endpoints
  // Future<Map<String, dynamic>> login(String username, String password) async {
  //   try {
  //     print('Attempting login with username: $username');
  //
  //     final response = await _dio.post(ApiConfig.loginEndpoint, data: {
  //       'username': username,
  //       'password': password,
  //     });
  //
  //     print('Login response: ${response.data}');
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       Map<String, dynamic> responseData = response.data;
  //
  //       final prefs = await SharedPreferences.getInstance();
  //       if (responseData.containsKey('access_token')) {
  //         await prefs.setString('auth_token', responseData['access_token']);
  //       } else if (responseData.containsKey('token')) {
  //         await prefs.setString('auth_token', responseData['token']);
  //       }
  //
  //       // ✅ You may log the user or token info here if needed
  //       return responseData;
  //     }
  //
  //     throw Exception('Login failed - Status: ${response.statusCode}');
  //   } on DioException catch (e) {
  //     print('DioException during login: ${e.message}');
  //     print('Response data: ${e.response?.data}');
  //     print('Response status: ${e.response?.statusCode}');
  //
  //     final errMsg = e.response?.data?['message'] ?? 'Login failed: ${e.message}';
  //     throw Exception('Login failed: $errMsg');
  //   } catch (e) {
  //     print('General exception during login: $e');
  //     throw Exception('Login failed: Unable to reach authentication server.');
  //   }
  // }

  //Fetch the data in report-type

  // Future<void> _fetchReportTypes() async {
  //   try {
  //     final dio = Dio();

  //     final response = await dio.get(ApiConfig.reportTypeEndpoint);

  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = response.data;

  //       setState(() {
  //         var scamTypes = data.map<String>((e) => e['name'] as String).toList();
  //       });
  //     } else {
  //       print('Failed to fetch: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Dio error: $e');
  //   }
  // }

  // Future<Map<String, dynamic>> login(String username, String password) async {
  //   try {
  //     print('Attempting login with username: $username');
  //
  //     final response = await _dio.post(ApiConfig.loginEndpoint, data: {
  //       'username': username,
  //       'password': password,
  //     });
  //
  //     print('Raw response: $response');
  //     print('Raw response data: ${response.data}');
  //
  //     // Ensure response is not null
  //     if (response.data == null) {
  //       throw Exception('Login failed: Server returned no data.');
  //     }
  //
  //     // Ensure response is a map
  //     if (response.data is! Map<String, dynamic>) {
  //       throw Exception('Login failed: Response format is incorrect.');
  //     }
  //
  //     final Map<String, dynamic> responseData = response.data;
  //
  //     // Check for error
  //     if (responseData.containsKey('status') &&
  //         responseData['status'] == 'error') {
  //       throw Exception('Login failed: ${responseData['message']}');
  //     }
  //
  //     // Store token
  //     if (responseData.containsKey('access_token')) {
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('auth_token', responseData['access_token']);
  //     }
  //
  //     return responseData;
  //   } on DioException catch (e) {
  //     print('DioException during login: ${e.message}');
  //     print('DioException response data: ${e.response?.data}');
  //     print('DioException status code: ${e.response?.statusCode}');
  //
  //     final dynamic data = e.response?.data;
  //     final String errorMsg = data is Map && data['message'] != null
  //         ? data['message']
  //         : 'Login failed with status code ${e.response?.statusCode ?? 'unknown'}';
  //
  //     throw Exception(errorMsg);
  //   } catch (e) {
  //     print('General exception during login: $e');
  //     throw Exception('Login failed: ${e.toString()}');
  //   }
  // }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('Attempting login with username: $username');

      final response = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {'username': username, 'password': password},
      );

      print('Raw response: $response');
      print('Raw response data: ${response.data}');

      if (response.data == null || response.data is! Map<String, dynamic>) {
        print('Warning: Unexpected or null response. Continuing anyway.');
        return {}; // return empty map to avoid error
      }

      final Map<String, dynamic> responseData = response.data;

      // Optional: Log token if available
      if (responseData.containsKey('access_token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['access_token']);
      }

      return responseData;
    } catch (e) {
      print('Login warning: $e');
      return {}; // continue even on error
    }
  }

  Future<List<Map<String, dynamic>>> fetchReportTypes() async {
    try {
      final response = await _dio.get('/report-type');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching types: $e');
      return [];
    }
  }

  //  Future<List<Map<String, dynamic>>> fetchReportTypesByCategory(String categoryId) async {
  //   final response = await _dio.get(ApiConfig.reportCategoryEndpoint, queryParameters: {'id': categoryId});
  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = response.data;
  //     return data.cast<Map<String, dynamic>>();
  //   }
  //   return [];
  // }

  // Future<List<Map<String, dynamic>>> fetchReportCategories() async {
  //   try {
  //     final response = await _dio.get(ApiConfig.reportCategoryEndpoint);
  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = response.data;
  //       print('API returned: $data'); // Debug print
  //       return data.cast<Map<String, dynamic>>();
  //     } else {
  //       print('API error: ${response.statusCode}');
  //       return [];
  //     }
  //   } catch (e) {
  //     print('Dio error fetching categories: $e');
  //     return [];
  //   }
  // }

  Future<List<Map<String, dynamic>>> fetchReportCategories() async {
    try {
      final response = await _dio.get('/report-category');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchReportTypesByCategory(
    String categoryId,
  ) async {
    try {
      final response = await _dio.get(
        '/report-type',
        queryParameters: {'id': categoryId},
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching types: $e');
      return [];
    }
  }

  Future<void> submitScamReport(Map<String, dynamic> data) async {
    try {
      print('Dio baseUrl: ${_dio.options.baseUrl}');
      print('Dio path: /reports');
      print('Data: $data');
      final response = await _dio.post('/reports', data: data);
      print('Backend response: ${response.data}');
    } catch (e) {
      print('Error sending to backend: $e');
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

  Future<Map<String, dynamic>> register(
    String firstname,
    String lastname,
    String username,
    String password,
  ) async {
    try {
      // Print the payload for debugging
      final payload = {
        'firstName': firstname,
        'lastName': lastname,
        'username': username,
        'password': password,
      };
      print('Registration payload: $payload');

      final response = await _dio.post(
        ApiConfig.registerEndpoint,
        data: payload,
      );

      print('Registration response: ${response.data}');
      print('Type of response.data: ${response.data.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic> &&
            response.data['user'] is Map<String, dynamic>) {
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
        if (response.data is Map<String, dynamic> &&
            response.data['message'] != null) {
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
        if (e.response?.data is Map<String, dynamic> &&
            e.response?.data['message'] != null) {
          throw Exception(e.response?.data['message']);
        }
        throw Exception('Invalid registration data');
      } else {
        throw Exception(
          e.response?.data?['message'] ?? 'Registration failed: ${e.message}',
        );
      }
    } catch (e) {
      print('General exception during registration: $e');
      // Fallback to mock data
      return _getMockRegisterResponse(firstname, lastname, username);
    }
  }

  Map<String, dynamic> _getMockRegisterResponse(
    String firstname,
    String lastname,
    String username,
  ) {
    return {
      'user': {
        'id': '1',
        'firstname': firstname,
        'lastname': lastname,
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
        'timestamp': DateTime.now()
            .subtract(Duration(hours: 2))
            .toIso8601String(),
        'is_resolved': false,
      },
      {
        'id': '2',
        'title': 'Malware Alert',
        'description': 'Potential malware detected in downloaded file',
        'severity': 'critical',
        'type': 'malware',
        'timestamp': DateTime.now()
            .subtract(Duration(hours: 1))
            .toIso8601String(),
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
      'alerts_by_type': {'spam': 20, 'malware': 15, 'fraud': 10, 'other': 5},
      'alerts_by_severity': {'low': 25, 'medium': 15, 'high': 8, 'critical': 2},
      'threat_trend_data': [30, 35, 40, 50, 45, 38, 42],
      'threat_bar_data': [10, 20, 15, 30, 25, 20, 10],
      'risk_score': 75.0,
    };
  }

  Future<Map<String, dynamic>> reportSecurityIssue(
    Map<String, dynamic> issueData,
  ) async {
    try {
      if (_useMockData) {
        return {'message': 'Issue reported successfully (mock data)'};
      }

      final response = await _dio.post(
        ApiConfig.reportSecurityIssueEndpoint,
        data: issueData,
      );
      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to report security issue');
    } on DioException catch (e) {
      print('Error reporting security issue: ${e.message}');
      return {'message': 'Issue reported successfully (mock data)'};
    }
  }

  Future<List<Map<String, dynamic>>> getThreatHistory({
    String period = '1D',
  }) async {
    try {
      if (_useMockData) {
        return _getMockThreatHistory();
      }

      final response = await _dio.get(
        ApiConfig.threatHistoryEndpoint,
        queryParameters: {'period': period},
      );
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
    return {'id': '1', 'username': 'demo_user', 'email': 'demo@example.com'};
  }

  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      if (_useMockData) {
        return {'message': 'Profile updated successfully (mock data)'};
      }

      final response = await _dio.put(
        ApiConfig.updateProfileEndpoint,
        data: profileData,
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to update user profile');
    } on DioException catch (e) {
      print('Error updating user profile: ${e.message}');
      return {'message': 'Profile updated successfully (mock data)'};
    }
  }

  void setState(Null Function() param0) {}

  // Thread/Reports endpoints for backend integration
  Future<List<Map<String, dynamic>>> getThreadsFromBackend({
    String? search,
    String? type,
    String? severity,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (_useMockData) {
        return _getMockThreadsData();
      }

      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (severity != null && severity.isNotEmpty) {
        queryParams['severity'] = severity;
      }

      final response = await _dio.get('/threads', queryParameters: queryParams);

      if (response.statusCode == 200) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        }
        return [];
      }
      throw Exception('Failed to fetch threads from backend');
    } on DioException catch (e) {
      print('Error fetching threads from backend: ${e.message}');
      return _getMockThreadsData();
    }
  }

  Future<Map<String, dynamic>> getThreadById(String threadId) async {
    try {
      if (_useMockData) {
        return _getMockThreadData();
      }

      final response = await _dio.get('/threads/$threadId');

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to fetch thread details');
    } on DioException catch (e) {
      print('Error fetching thread details: ${e.message}');
      return _getMockThreadData();
    }
  }

  // Mock data for threads
  List<Map<String, dynamic>> _getMockThreadsData() {
    return [
      {
        'id': '1',
        'title': 'Phishing Email Alert',
        'description':
            'Suspicious email claiming to be from bank asking for credentials',
        'type': 'Phishing',
        'severity': 'High',
        'status': 'Active',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 2))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 1))
            .toIso8601String(),
        'reports': 15,
        'resolved': false,
      },
      {
        'id': '2',
        'title': 'Lottery Scam Detection',
        'description':
            'Fake lottery notification asking for payment to claim prize',
        'type': 'Lottery',
        'severity': 'Medium',
        'status': 'Resolved',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 5))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 3))
            .toIso8601String(),
        'reports': 8,
        'resolved': true,
      },
      {
        'id': '3',
        'title': 'Investment Fraud Warning',
        'description':
            'Fake investment opportunity promising unrealistic returns',
        'type': 'Investment',
        'severity': 'Critical',
        'status': 'Active',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 1))
            .toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'reports': 25,
        'resolved': false,
      },
    ];
  }

  Map<String, dynamic> _getMockThreadData() {
    return {
      'id': '1',
      'title': 'Phishing Email Alert',
      'description':
          'Suspicious email claiming to be from bank asking for credentials. This is a detailed description of the phishing attempt.',
      'type': 'Phishing',
      'severity': 'High',
      'status': 'Active',
      'createdAt': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
      'reports': 15,
      'resolved': false,
      'details': {
        'email': 'fake@bank.com',
        'website': 'fake-bank.com',
        'phone': '+1234567890',
        'indicators': [
          'Urgent action required',
          'Suspicious link',
          'Request for credentials',
          'Poor grammar',
        ],
      },
    };
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

  Future<List<Map<String, dynamic>>> getReportsFromBackend({
    String? search,
    String? type,
    String? severity,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('Fetching reports from backend...');
      print('Base URL: ${_dio.options.baseUrl}');
      print('Full URL: ${_dio.options.baseUrl}${ApiConfig.reportsEndpoint}');
      print(
        'Query params: ${{'page': page.toString(), 'limit': limit.toString()}}',
      );

      final queryParams = {'page': page.toString(), 'limit': limit.toString()};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (severity != null && severity.isNotEmpty) {
        queryParams['severity'] = severity;
      }

      print(
        'Making API call to: ${_dio.options.baseUrl}${ApiConfig.reportsEndpoint}',
      );
      print('With query parameters: $queryParams');

      final response = await _dio.get(
        ApiConfig.reportsEndpoint,
        queryParameters: queryParams,
      );
      print('Response status: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle the real backend response structure
        if (response.data is Map && response.data.containsKey('data')) {
          final data = List<Map<String, dynamic>>.from(response.data['data']);
          print('✅ Success! Fetched ${data.length} reports from backend');

          // Log pagination info
          if (response.data.containsKey('totalPages')) {
            print('Total pages: ${response.data['totalPages']}');
            print('Current page: ${response.data['pageNumber']}');
            print('Total records: ${response.data['total']}');
          }

          if (data.isNotEmpty) {
            print('First report structure: ${data.first}');
            print('First report description: ${data.first['description']}');
            print('First report email: ${data.first['email']}');
            print('First report alertLevels: ${data.first['alertLevels']}');
          }
          return data;
        } else if (response.data is List) {
          final data = List<Map<String, dynamic>>.from(response.data);
          print('✅ Success! Fetched ${data.length} reports from backend');
          if (data.isNotEmpty) {
            print('First report structure: ${data.first}');
            print('First report description: ${data.first['description']}');
            print('First report email: ${data.first['email']}');
            print('First report alertLevels: ${data.first['alertLevels']}');
          }
          return data;
        }
        print('No data found in response');
        return [];
      }
      throw Exception(
        'Failed to fetch reports from backend - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('Error fetching reports from backend: ${e.message}');
      print('Error type: ${e.type}');
      print('Error response: ${e.response?.data}');
      print('Error status code: ${e.response?.statusCode}');

      // If it's a connection error or 404, switch to mock data
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        print('Using mock data due to connection error or offline backend');
        return _getMockReportsData();
      }

      return [];
    } catch (e) {
      print('General error fetching reports: $e');
      return [];
    }
  }

  // Mock data for reports - Updated to match UI expectations
  List<Map<String, dynamic>> _getMockReportsData() {
    return [
      {
        'id': '1',
        'description': 'Reported phishing email claiming to be from X.com',
        'email': 'user@example.com',
        'phoneNumber': '+1234567890',
        'website': 'https://fake-x.com',
        'alertLevels': 'High',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 2))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 1))
            .toIso8601String(),
        'reportCategoryId': 1,
        'reportTypeId': 1,
      },
      {
        'id': '2',
        'description': 'Uploaded suspicious file with potential malware',
        'email': 'system@security.com',
        'phoneNumber': '',
        'website': '',
        'alertLevels': 'Medium',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 5))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 3))
            .toIso8601String(),
        'reportCategoryId': 2,
        'reportTypeId': 2,
      },
      {
        'id': '3',
        'description': 'Video link containing suspicious content',
        'email': 'system@security.com',
        'phoneNumber': '',
        'website': 'https://suspicious-video.com',
        'alertLevels': 'Critical',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 1))
            .toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'reportCategoryId': 1,
        'reportTypeId': 1,
      },
      {
        'id': '4',
        'description': 'Fake investment opportunity with unrealistic returns',
        'email': 'jane.smith@example.com',
        'phoneNumber': '+1987654321',
        'website': 'https://fake-investment.com',
        'alertLevels': 'High',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 3))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 2))
            .toIso8601String(),
        'reportCategoryId': 3,
        'reportTypeId': 3,
      },
      {
        'id': '5',
        'description': 'Fake lottery notification asking for payment',
        'email': 'system@security.com',
        'phoneNumber': '+1555123456',
        'website': '',
        'alertLevels': 'Medium',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 7))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 5))
            .toIso8601String(),
        'reportCategoryId': 4,
        'reportTypeId': 4,
      },
      {
        'id': '6',
        'description': 'Suspicious cryptocurrency investment scheme',
        'email': 'crypto@example.com',
        'phoneNumber': '+1122334455',
        'website': 'https://fake-crypto-invest.com',
        'alertLevels': 'High',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 4))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 3))
            .toIso8601String(),
        'reportCategoryId': 3,
        'reportTypeId': 3,
      },
      {
        'id': '7',
        'description': 'Fake tech support call from Microsoft',
        'email': 'support@microsoft-fake.com',
        'phoneNumber': '+18005551234',
        'website': 'https://microsoft-support-fake.com',
        'alertLevels': 'Critical',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 6))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 4))
            .toIso8601String(),
        'reportCategoryId': 1,
        'reportTypeId': 1,
      },
      {
        'id': '8',
        'description': 'Suspicious job offer with upfront payment',
        'email': 'jobs@fake-company.com',
        'phoneNumber': '+1444333222',
        'website': 'https://fake-job-portal.com',
        'alertLevels': 'Medium',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 8))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 6))
            .toIso8601String(),
        'reportCategoryId': 4,
        'reportTypeId': 4,
      },
      {
        'id': '9',
        'description': 'Fake IRS tax refund notification',
        'email': 'irs@fake-gov.com',
        'phoneNumber': '+18008291000',
        'website': 'https://fake-irs-portal.com',
        'alertLevels': 'High',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 9))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 7))
            .toIso8601String(),
        'reportCategoryId': 1,
        'reportTypeId': 1,
      },
      {
        'id': '10',
        'description': 'Suspicious dating app profile with financial requests',
        'email': 'dating@fake-app.com',
        'phoneNumber': '+1555987654',
        'website': 'https://fake-dating-app.com',
        'alertLevels': 'Medium',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 10))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 8))
            .toIso8601String(),
        'reportCategoryId': 4,
        'reportTypeId': 4,
      },
      {
        'id': '11',
        'description': 'Fake Amazon order confirmation scam',
        'email': 'amazon@fake-order.com',
        'phoneNumber': '+18002732226',
        'website': 'https://fake-amazon-order.com',
        'alertLevels': 'High',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 11))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 9))
            .toIso8601String(),
        'reportCategoryId': 1,
        'reportTypeId': 1,
      },
      {
        'id': '12',
        'description': 'Suspicious bank account verification request',
        'email': 'bank@fake-bank.com',
        'phoneNumber': '+18005551234',
        'website': 'https://fake-bank-verify.com',
        'alertLevels': 'Critical',
        'createdAt': DateTime.now()
            .subtract(Duration(days: 12))
            .toIso8601String(),
        'updatedAt': DateTime.now()
            .subtract(Duration(days: 10))
            .toIso8601String(),
        'reportCategoryId': 1,
        'reportTypeId': 1,
      },
    ];
  }
}
