import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/filter_model.dart';
import '../models/report_model.dart';

// Reports Filter Class for Dynamic API Calls


class ApiService {
  late Dio _dioAuth; // For Auth server
  late Dio _dioMain; // For Main server
  bool _useMockData = false;

  ApiService() {
    // Auth Server Dio
    _dioAuth = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl1,
      contentType: 'application/json',
      connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
      headers: ApiConfig.defaultHeaders,
    ));

    // Main Server Dio
    _dioMain = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl2,
      contentType: 'application/json',
      connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
      headers: ApiConfig.defaultHeaders,
    ));

    _setupInterceptors(_dioAuth);
    _setupInterceptors(_dioMain);
  }

  void _setupInterceptors(Dio dio) {
    if (ApiConfig.enableLogging) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ));
    }

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final retryToken = await _getAccessToken();
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $retryToken';
            final retryResponse = await dio.fetch(opts);
            return handler.resolve(retryResponse);
          }
        }
        return handler.next(error);
      },
    ));

  }

  Future<void> setUseMockData(bool value) async {
    _useMockData = value;
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      print('Attempting token refresh with: $refreshToken');
      if (refreshToken == null) return false;

      final response = await _dioAuth.post(
        'https://4795a8bab1f1.ngrok-free.app/auth/refresh-token',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      print('New access token: $newAccessToken');
      await _saveTokens(newAccessToken, newRefreshToken);
      return true;
    } catch (e) {
      print('Token refresh failed: $e');
      return false;
    }
  }


  Future<Response> get(String url) async {
    return _dioAuth.get(url);
  }

  Future<Response> post(String url, dynamic data) async {
    return _dioAuth.post(url, data: data);
  }

  Future<Response> getProfile() async {
    try {
      final response = await _dioAuth.get('https://4795a8bab1f1.ngrok-free.app/user/me');
      return response;
    } catch (e) {
      print('Failed to get user profile: $e');
      rethrow;
    }
  }








  //////////////////////////////////////////////////////////////////////


  // Example: Login using Auth Server
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('Attempting login with username: $username');

      final response = await _dioAuth.post('https://4795a8bab1f1.ngrok-free.app/auth/login-user', data: {
        'username': username,
        'password': password,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
      );

      print('Raw response: ${response}');
      print('Raw response data: ${response.data}');

      if (response.data == null || response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response from server');
      }

      final Map<String, dynamic> responseData = response.data;

      final prefs = await SharedPreferences.getInstance();

      // Save tokens if available
      if (responseData.containsKey('access_token')) {
        await prefs.setString('auth_token', responseData['access_token']);
        print('access_token: ${responseData['access_token']}');
      }
      if (responseData.containsKey('refresh_token')) {
        await prefs.setString('refresh_token', responseData['refresh_token']);
        print('refresh_token: ${responseData['refresh_token']}');
      }
      if (responseData.containsKey('id_token')) {
        await prefs.setString('id_token', responseData['id_token']);
        print('id_token: ${responseData['id_token']}');
      }

      // Optional fallback if user data not available
      if (!responseData.containsKey('user')) {
        responseData['user'] = {
          'username': username, // fallback to input
          'email': '',
          'name': '',
        };
      }

      return responseData;
    } on DioException catch (e) {
      print('DioException during login: ${e.message}');
      print('DioException response data: ${e.response?.data}');
      print('DioException status code: ${e.response?.statusCode}');

      final errMsg = e.response?.data is Map<String, dynamic>
          ? e.response?.data['message'] ?? 'Unknown error'
          : e.message;

      throw Exception('Login failed: $errMsg');
    } catch (e) {
      print('General exception during login: $e');
      throw Exception('Login failed: Invalid response from server');
    }
  }
  // Example: Fetch dashboard stats using Main Server
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await _dioMain.get(ApiConfig.dashboardStatsEndpoint);

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      print("Error fetching stats: $e");
      return null;
    }
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

      final response = await _dioAuth.post(ApiConfig.registerEndpoint, data: payload);

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
  Map<String, dynamic> _getMockLoginResponse(String username) {
    return {
      'user': {
        'id': '1',
        'username': username,
        'email': '$username@example.com',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      'token': 'mock_token_${DateTime
          .now()
          .millisecondsSinceEpoch}',
      'message': 'Login successful (mock data)',
    };
  }

  Map<String, dynamic> _getMockRegisterResponse(String firstname, String lastname, String username) {
    return {
      'user': {
        'id': '1',
        'firstName':firstname,
        'lastName':lastname,
        'username': username,
      },
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Registration successful (mock data)',
    };
  }

  Future<void> logout() async {
    try {
      if (!_useMockData) {
        await _dioAuth.post(ApiConfig.logoutEndpoint);
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

      final response = await _dioMain.get(ApiConfig.securityAlertsEndpoint);
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
        'timestamp': DateTime
            .now()
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
        'timestamp': DateTime
            .now()
            .subtract(Duration(hours: 1))
            .toIso8601String(),
        'is_resolved': true,
      },
    ];
  }

  // Future<Map<String, dynamic>> getDashboardStats() async {
  //   try {
  //     if (_useMockData) {
  //       return _getMockDashboardStats();
  //     }
  //
  //     final response = await _dioMain.get(ApiConfig.dashboardStatsEndpoint);
  //     if (response.statusCode == 200) {
  //       return response.data;
  //     }
  //     throw Exception('Failed to fetch dashboard stats');
  //   } on DioException catch (e) {
  //     print('Error fetching dashboard stats: ${e.message}');
  //     // Return mock data
  //     return _getMockDashboardStats();
  //   }
  // }

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

  Future<Map<String, dynamic>> reportSecurityIssue(
      Map<String, dynamic> issueData) async {
    try {
      if (_useMockData) {
        return {'message': 'Issue reported successfully (mock data)'};
      }

      final response = await _dioMain.post(
          ApiConfig.reportSecurityIssueEndpoint, data: issueData);
      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to report security issue');
    } on DioException catch (e) {
      print('Error reporting security issue: ${e.message}');
      return {'message': 'Issue reported successfully (mock data)'};
    }
  }

  Future<List<Map<String, dynamic>>> getThreatHistory(
      {String period = '1D'}) async {
    try {
      if (_useMockData) {
        return _getMockThreatHistory();
      }

      final response = await _dioMain.get(
          ApiConfig.threatHistoryEndpoint, queryParameters: {
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
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (_useMockData) {
        return _getMockUserProfile();
      }

      final response = await _dioAuth.get(ApiConfig.userProfileEndpoint);

      print('response data$response');
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

  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> profileData) async {
    try {
      if (_useMockData) {
        return {'message': 'Profile updated successfully (mock data)'};
      }

      final response = await _dioAuth.put(
          ApiConfig.updateProfileEndpoint, data: profileData);
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to update user profile');
    } on DioException catch (e) {
      print('Error updating user profile: ${e.message}');
      return {'message': 'Profile updated successfully (mock data)'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchReportCategories() async {
    try {
      final response = await _dioMain.get('/report-category');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

   Future<List<Map<String, dynamic>>> fetchReportTypesByCategory(String categoryId) async {
    try {
      final response = await _dioMain.get('/report-type', queryParameters: {'id': categoryId});
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching types: $e');
      return [];
    }
  }

   Future<void> submitScamReport(Map<String, dynamic> data) async {
    try {
      print('Dio baseUrl: ${_dioMain.options.baseUrl}');
      print('Dio path: /reports');
      print('Data: $data');
      final response = await _dioMain.post('/reports', data: data);
      print('Backend response: ${response.data}');
    } catch (e) {
      print('Error sending to backend: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchReportTypes() async {
    try {
      final response = await _dioMain.get('/report-type');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching types: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> fetchAllReports() async {
    try {
      print('=== FETCHING ALL REPORTS ===');
      print('Using base URL: ${_dioMain.options.baseUrl}');
      print('Making GET request to: /reports');
      
      final response = await _dioMain.get('/reports');
      
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');

      // Check if response.data is a List before converting
      if (response.data is List) {
        final reports = List<Map<String, dynamic>>.from(response.data);
        print('Successfully converted response to List with ${reports.length} reports');
        return reports;
      } else if (response.data is Map) {
        // Handle paginated response structure
        final responseMap = response.data as Map<String, dynamic>;
        print('Backend returned Map with keys: ${responseMap.keys}');
        
        // Check if the response has a 'data' field (pagination structure)
        if (responseMap.containsKey('data')) {
          final dataField = responseMap['data'];
          print('Found data field: $dataField (type: ${dataField.runtimeType})');
          
          if (dataField is List) {
            final reports = List<Map<String, dynamic>>.from(dataField);
            print('Successfully extracted ${reports.length} reports from data field');
            
            // Debug: Print first report if available
            if (reports.isNotEmpty) {
              print('First report structure:');
              reports.first.forEach((key, value) {
                print('  $key: $value (${value.runtimeType})');
              });
            }
            
            return reports;
          } else if (dataField is Map) {
            print('Data field is a Map, not a List: $dataField');
            return [];
          } else {
            print('Data field is neither List nor Map: ${dataField.runtimeType}');
            return [];
          }
        } else {
          // If it's a Map but doesn't have 'data' field, return empty list
          print('Map response without data field: ${response.data}');
          return [];
        }
      } else {
        print('Unexpected response data type: ${response.data.runtimeType}');
        print('Response data value: ${response.data}');
        return [];
      }
    } catch (e) {
      print('Error fetching all reports: $e');
      if (e is DioException) {
        print('DioException details:');
        print('- Type: ${e.type}');
        print('- Message: ${e.message}');
        print('- Response status: ${e.response?.statusCode}');
        print('- Response data: ${e.response?.data}');
      }
      return [];
    }
  }

  // Test method to check different endpoints
  Future<void> testBackendEndpoints() async {
    try {
      print('=== TESTING BACKEND ENDPOINTS ===');
      
      // Test the main reports endpoint
      print('Testing /reports endpoint...');
      final reportsResponse = await _dioMain.get('/reports');
      print('Reports response: ${reportsResponse.data}');
      
      // Test if there are any other endpoints
      print('Testing /report-type endpoint...');
      try {
        final typesResponse = await _dioMain.get('/report-type');
        print('Types response: ${typesResponse.data}');
      } catch (e) {
        print('Types endpoint error: $e');
      }
      
      print('Testing /report-category endpoint...');
      try {
        final categoriesResponse = await _dioMain.get('/report-category');
        print('Categories response: ${categoriesResponse.data}');
      } catch (e) {
        print('Categories endpoint error: $e');
      }
      
    } catch (e) {
      print('Backend endpoint test failed: $e');
    }
  }


  Future<Map<String, dynamic>?> fetchCategoryById(String categoryId) async {
    try {
      final response = await _dioMain.get('/report-category/$categoryId');
      return response.data;
    } catch (e) {
      print('Error fetching category by ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchTypeById(String typeId) async {
    try {
      final response = await _dioMain.get('/report-type/$typeId');
      return response.data;
    } catch (e) {
      print('Error fetching type by ID: $e');
      return null;
    }
  }

  // Method to fetch reports with dynamic filtering
  Future<List<Map<String, dynamic>>> fetchReportsWithFilter(ReportsFilter filter) async {
    try {
      print('=== FETCHING REPORTS WITH FILTER ===');
      print('Filter: $filter');
      print('Built URL: ${filter.buildUrl()}');
      print('Query Parameters: ${filter.toQueryParameters()}');
      
      final response = await _dioMain.get(
        '/reports',
        queryParameters: filter.toQueryParameters(),
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');

      // Handle different response structures
      if (response.data is List) {
        final reports = List<Map<String, dynamic>>.from(response.data);
        print('Successfully converted response to List with ${reports.length} reports');
        return reports;
      } else if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        print('Backend returned Map with keys: ${responseMap.keys}');
        
        // Handle paginated response structure
        if (responseMap.containsKey('data')) {
          final dataField = responseMap['data'];
          print('Found data field: $dataField (type: ${dataField.runtimeType})');
          
          if (dataField is List) {
            final reports = List<Map<String, dynamic>>.from(dataField);
            print('Successfully extracted ${reports.length} reports from data field');
            return reports;
          } else {
            print('Data field is not a List: ${dataField.runtimeType}');
            return [];
          }
        } else {
          print('Map response without data field: ${response.data}');
          return [];
        }
      } else {
        print('Unexpected response data type: ${response.data.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Error fetching reports with filter: $e');
      if (e is DioException) {
        print('DioException details:');
        print('- Type: ${e.type}');
        print('- Message: ${e.message}');
        print('- Response status: ${e.response?.statusCode}');
        print('- Response data: ${e.response?.data}');
      }
      return [];
    }
  }

  // Convenience method for simple search
  Future<List<Map<String, dynamic>>> searchReports(String searchQuery, {
    int? page,
    int? limit,
  }) async {
    final filter = ReportsFilter(
      search: searchQuery,
      page: page,
      limit: limit,
    );
    return fetchReportsWithFilter(filter);
  }

  // Convenience method for category-based filtering
  Future<List<Map<String, dynamic>>> getReportsByCategory(String categoryId, {
    int? page,
    int? limit,
    String? search,
  }) async {
    final filter = ReportsFilter(
      reportCategoryId: categoryId,
      page: page,
      limit: limit,
      search: search,
    );
    return fetchReportsWithFilter(filter);
  }

  // Convenience method for type-based filtering
  Future<List<Map<String, dynamic>>> getReportsByType(String typeId, {
    int? page,
    int? limit,
    String? search,
  }) async {
    final filter = ReportsFilter(
      reportTypeId: typeId,
      page: page,
      limit: limit,
      search: search,
    );
    return fetchReportsWithFilter(filter);
  }

  // Method to build complex filter from multiple parameters
  Future<List<Map<String, dynamic>>> getReportsWithComplexFilter({
    String? searchQuery,
    List<String>? categoryIds,
    List<String>? typeIds,
    List<String>? severityLevels,
    int? page,
    int? limit,
    String? deviceTypeId,
    String? detectTypeId,
    String? operatingSystemName,
  }) async {
    // Build filter parameters
    final Map<String, dynamic> queryParams = {};
    
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (searchQuery != null && searchQuery.isNotEmpty) queryParams['search'] = searchQuery;
    if (deviceTypeId != null) queryParams['deviceTypeId'] = deviceTypeId;
    if (detectTypeId != null) queryParams['detectTypeId'] = detectTypeId;
    if (operatingSystemName != null) queryParams['operatingSystemName'] = operatingSystemName;
    
    // Handle multiple category IDs (join with comma if multiple)
    if (categoryIds != null && categoryIds.isNotEmpty) {
      queryParams['reportCategoryId'] = categoryIds.join(',');
    }
    
    // Handle multiple type IDs (join with comma if multiple)
    if (typeIds != null && typeIds.isNotEmpty) {
      queryParams['reportTypeId'] = typeIds.join(',');
    }
    
    // Handle severity levels (join with comma if multiple)
    if (severityLevels != null && severityLevels.isNotEmpty) {
      queryParams['severity'] = severityLevels.join(',');
    }

    try {
      print('=== FETCHING REPORTS WITH COMPLEX FILTER ===');
      print('Query Parameters: $queryParams');
      
      final response = await _dioMain.get(
        '/reports',
        queryParameters: queryParams,
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');

      // Handle response data
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data')) {
          final dataField = responseMap['data'];
          if (dataField is List) {
            return List<Map<String, dynamic>>.from(dataField);
          }
        }
      }
      return [];
    } catch (e) {
      print('Error fetching reports with complex filter: $e');
      return [];
    }
  }

  // Method to test the exact URL structure you provided
  // Future<List<Map<String, dynamic>>> testExactUrlStructure() async {
  //   final filter = ReportsFilter(
  //     page: 1,
  //     limit: 100,
  //     reportCategoryId: 'https://c61c0359421d.ngrok-free.app',
  //     reportTypeId: '68752de7a40625496c08b42a',
  //     deviceTypeId: '687616edc688f12536d1d2d5',
  //     detectTypeId: '68761767c688f12536d1d2dd',
  //     operatingSystemName: '6875f41f652eaccf5ecbe6b2',
  //     search: 'scam',
  //   );
  //
  //   print('Testing exact URL structure:');
  //   print('Built URL: ${filter.buildUrl()}');
  //   print('Expected: /reports?page=1&limit=100&reportCategoryId=https%3A%2F%2Fc61c0359421d.ngrok-free.app&reportTypeId=68752de7a40625496c08b42a&deviceTypeId=687616edc688f12536d1d2d5&detectTypeId=68761767c688f12536d1d2dd&operatingSystemName=6875f41f652eaccf5ecbe6b2&search=scam');
  //
  //   return fetchReportsWithFilter(filter);
  // }

  // ============================================================================
  // USAGE EXAMPLES AND DOCUMENTATION
  // ============================================================================
  
  /*
  HOW TO USE THE DYNAMIC API CALLS:
  
  1. SIMPLE SEARCH:
  ```dart
  final reports = await apiService.searchReports('scam', page: 1, limit: 50);
  ```
  
  2. CATEGORY-BASED FILTERING:
  ```dart
  final reports = await apiService.getReportsByCategory('category_id_here', 
    page: 1, limit: 100, search: 'malware');
  ```
  
  3. TYPE-BASED FILTERING:
  ```dart
  final reports = await apiService.getReportsByType('type_id_here', 
    page: 1, limit: 100, search: 'phishing');
  ```
  
  4. COMPLEX FILTERING WITH MULTIPLE PARAMETERS:
  ```dart
  final reports = await apiService.getReportsWithComplexFilter(
    searchQuery: 'scam',
    categoryIds: ['cat1', 'cat2'],
    typeIds: ['type1', 'type2'],
    severityLevels: ['high', 'critical'],
    page: 1,
    limit: 100,
    deviceTypeId: 'device_id',
    detectTypeId: 'detect_id',
    operatingSystemName: 'os_name',
  );
  ```
  
  5. CUSTOM FILTER OBJECT:
  ```dart
  final filter = ReportsFilter(
    page: 1,
    limit: 100,
    reportCategoryId: 'category_id',
    reportTypeId: 'type_id',
    deviceTypeId: 'device_id',
    detectTypeId: 'detect_id',
    operatingSystemName: 'os_name',
    search: 'search_term',
  );
  
  final reports = await apiService.fetchReportsWithFilter(filter);
  ```
  
  6. BUILDING URL MANUALLY:
  ```dart
  final filter = ReportsFilter(
    page: 1,
    limit: 100,
    search: 'scam',
  );
  
  print('URL: ${filter.buildUrl()}');
  // Output: /reports?page=1&limit=100&search=scam
  ```
  
  7. TESTING THE EXACT URL STRUCTURE:
  ```dart
  final reports = await apiService.testExactUrlStructure();
  ```
  
  URL BREAKDOWN EXPLANATION:
  
  Your URL: https://c61c0359421d.ngrok-free.app/reports?page=1&limit=100&reportCategoryId=https%3A%2F%2Fc61c0359421d.ngrok-free.app&reportTypeId=68752de7a40625496c08b42a&deviceTypeId=687616edc688f12536d1d2d5&detectTypeId=68761767c688f12536d1d2dd&operatingSystemName=6875f41f652eaccf5ecbe6b2&search=scam
  
  Components:
  - Base URL: https://c61c0359421d.ngrok-free.app
  - Endpoint: /reports
  - Query Parameters:
    * page=1 (pagination)
    * limit=100 (number of results per page)
    * reportCategoryId=https%3A%2F%2Fc61c0359421d.ngrok-free.app (URL encoded)
    * reportTypeId=68752de7a40625496c08b42a (MongoDB ObjectId)
    * deviceTypeId=687616edc688f12536d1d2d5 (MongoDB ObjectId)
    * detectTypeId=68761767c688f12536d1d2dd (MongoDB ObjectId)
    * operatingSystemName=6875f41f652eaccf5ecbe6b2 (MongoDB ObjectId)
    * search=scam (search term)
  
  The ReportsFilter class handles:
  - URL encoding of parameters
  - Building query strings
  - Optional parameter handling
  - Multiple value support (comma-separated)
  - Type safety and validation
  */

//Fetch the data in report-type
}
