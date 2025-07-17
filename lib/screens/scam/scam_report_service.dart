import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/scam_report_model.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class ScamReportService {
  static final _box = Hive.box<ScamReportModel>('scam_reports');
  static final ApiService _apiService = ApiService();

  static Future<void> saveReport(ScamReportModel report) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      // Try to send to backend
      bool success = await sendToBackend(report);
      if (success) {
        report.isSynced = true;
      }
    }
    // Always save to local storage
    await _box.add(report);
  }

  static Future<void> saveReportOffline(ScamReportModel report) async {
    await _box.add(report);
  }

  static Future<void> syncReports() async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    final unsyncedReports = box.values.where((r) => r.isSynced != true).toList();

    for (var report in unsyncedReports) {
      try {
        // Send to backend with upsert logic
        final success = await ScamReportService.sendToBackend(report);
        if (success) {
          // Mark as synced
          final key = box.keyAt(box.values.toList().indexOf(report));
          final updated = report.copyWith(isSynced: true);
          await box.put(key, updated);
        }
      } catch (e) {
        print('Failed to sync report: $e');
      }
    }
  }

  static Future<bool> sendToBackend(ScamReportModel report) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl2}/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'reportCategoryId': report.reportCategoryId,
          'reportTypeId': report.reportTypeId,
          'alertLevels': report.alertLevels,
          'phoneNumber': report.phoneNumber,
          'email': report.email,
          'website': report.website,
          'description': report.description,
          'createdAt': report.createdAt?.toIso8601String(),
          'updatedAt': report.updatedAt?.toIso8601String(),
        }),
      );

      print('Send to backend response status: ${response.statusCode}');
      print('Send to backend response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error sending to backend: $e');
      return false;
    }
  }

  static Future<void> updateReport(ScamReportModel report) async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    await box.put(report.id, report);
  }

  static List<ScamReportModel> getLocalReports() {
    return _box.values.toList();
  }

  static Future<List<Map<String, dynamic>>> fetchReportTypes() async {
    return await _apiService.fetchReportTypes();
  }

  static Future<List<Map<String, dynamic>>> fetchReportTypesByCategory(
    String categoryId,
  ) async {
    return await _apiService.fetchReportTypesByCategory(categoryId);
  }

  static Future<List<Map<String, dynamic>>> fetchReportCategories() async {
    final categories = await _apiService.fetchReportCategories();
    print('API returned: $categories'); // Debug print
    return categories;
  }
}
