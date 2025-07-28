import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'jwt_service.dart';

class DioService {
  static final DioService _instance = DioService._internal();

  factory DioService() => _instance;

  late Dio authApi;
  late Dio mainApi;
  late Dio fileUploadApi;
  late Dio reportsApi;

  DioService._internal() {
    _initClients();
  }

  void _initClients() {
    // Auth API (for authentication endpoints)
    authApi = Dio(
      BaseOptions(
        baseUrl: ApiConfig.authBaseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
        contentType: 'application/json',
      ),
    );

    // Main API (for general endpoints)
    mainApi = Dio(
      BaseOptions(
        baseUrl: ApiConfig.mainBaseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
        contentType: 'application/json',
      ),
    );

    // File Upload API (for multipart uploads)
    fileUploadApi = Dio(
      BaseOptions(
        baseUrl: ApiConfig.fileUploadBaseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
        contentType: 'multipart/form-data',
      ),
    );

    // Reports API (for report-specific endpoints)
    reportsApi = Dio(
      BaseOptions(
        baseUrl: ApiConfig.reportsBaseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
        contentType: 'application/json',
      ),
    );

    // Apply interceptors to all clients
    _applyInterceptors(authApi);
    _applyInterceptors(mainApi);
    _applyInterceptors(fileUploadApi);
    _applyInterceptors(reportsApi);
  }

  void _applyInterceptors(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add default headers
          options.headers.addAll(ApiConfig.defaultHeaders);

          // Add authorization token
          final token = await JwtService.getTokenWithFallback();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add logging if enabled
          if (ApiConfig.enableLogging) {
            print('🌐 API Request: ${options.method} ${options.path}');
            print('📋 Headers: ${options.headers}');
            if (options.data != null) {
              print('📦 Data: ${options.data}');
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (ApiConfig.enableLogging) {
            print(
              '✅ API Response: ${response.statusCode} ${response.requestOptions.path}',
            );
            print('📄 Response Data: ${response.data}');
          }
          handler.next(response);
        },
        onError: (DioException e, handler) {
          if (ApiConfig.enableLogging) {
            print(
              '❌ API Error: ${e.response?.statusCode} ${e.requestOptions.path}',
            );
            print('🚨 Error Message: ${e.message}');
            print('📄 Error Response: ${e.response?.data}');
          }

          // Handle specific error cases
          if (e.response?.statusCode == 401) {
            // Token expired or invalid
            print('🔐 Unauthorized - Token may be expired');
            // You can add token refresh logic here
          }

          handler.next(e);
        },
      ),
    );
  }

  // Helper methods for common API operations
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await mainApi.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await mainApi.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await mainApi.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await mainApi.delete(path, queryParameters: queryParameters);
  }

  // Auth-specific methods
  Future<Response> authGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await authApi.get(path, queryParameters: queryParameters);
  }

  Future<Response> authPost(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await authApi.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response> authPut(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await authApi.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  // File upload method
  Future<Response> uploadFile(String path, FormData formData) async {
    return await fileUploadApi.post(path, data: formData);
  }

  // Reports-specific methods
  Future<Response> reportsGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await reportsApi.get(path, queryParameters: queryParameters);
  }

  Future<Response> reportsPost(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await reportsApi.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  // Utility method to create FormData for file uploads
  static Future<FormData> createFormData({
    required String filePath,
    String? fieldName = 'file',
    String? fileName,
    Map<String, dynamic>? additionalFields,
  }) async {
    final formData = FormData();

    // Add file
    formData.files.add(
      MapEntry(
        fieldName!,
        await MultipartFile.fromFile(
          filePath,
          filename: fileName ?? filePath.split('/').last,
        ),
      ),
    );

    // Add additional fields
    if (additionalFields != null) {
      formData.fields.addAll(
        additionalFields.entries.map(
          (e) => MapEntry(e.key, e.value.toString()),
        ),
      );
    }

    return formData;
  }
}

// Global instance
final dioService = DioService();

// Example usage functions (you can remove these if not needed)
Future<void> fetchUsers() async {
  try {
    final response = await dioService.get('/users');
    print('Users: ${response.data}');
  } catch (e) {
    print("Error fetching users: $e");
  }
}

Future<void> uploadImage(String imagePath) async {
  try {
    final formData = await DioService.createFormData(
      filePath: imagePath,
      fieldName: 'file',
      fileName: 'upload.jpg',
    );

    final response = await dioService.uploadFile('/upload', formData);
    print('Upload response: ${response.data}');
  } catch (e) {
    print("Error uploading image: $e");
  }
}
