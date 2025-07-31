import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/scam_report_model.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/jwt_service.dart';
import '../../services/report_reference_service.dart';

class ScamReportService {
  static final _box = Hive.box<ScamReportModel>('scam_reports');
  static final ApiService _apiService = ApiService();

  static Future<void> saveReport(ScamReportModel report) async {
    // Get current user ID from JWT token
    final keycloakUserId = await JwtService.getCurrentUserId();

    // Run diagnostics if no user ID found (device-specific issue)
    if (keycloakUserId == null) {
      print('⚠️ No user ID found - running token storage diagnostics...');
      await JwtService.diagnoseTokenStorage();
    }

    if (keycloakUserId != null) {
      report = report.copyWith(keycloakUserId: keycloakUserId);
    } else {
      // Fallback for device-specific issues
      print('⚠️ Using fallback user ID for device compatibility');
      report = report.copyWith(
        keycloakUserId: 'device_user_${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    // Ensure unique timestamp for each report
    final now = DateTime.now();
    final uniqueOffset = (report.id?.hashCode ?? 0) % 1000;
    final uniqueTimestamp = now.add(Duration(milliseconds: uniqueOffset));

    report = report.copyWith(
      createdAt: uniqueTimestamp,
      updatedAt: uniqueTimestamp,
    );

    // Always save to local storage first (offline-first approach)
    await _box.add(report);
    print('✅ Scam report saved locally with type ID: ${report.reportTypeId}');

    // Try to sync if online
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      print('🌐 Online - attempting to sync report...');
      try {
        // Initialize reference service before syncing
        await ReportReferenceService.initialize();
        bool success = await sendToBackend(report);
        if (success) {
          // Mark as synced
          final key = _box.keyAt(
            _box.length - 1,
          ); // Get the key of the last added item
          final updated = report.copyWith(isSynced: true);
          await _box.put(key, updated);
          print('✅ Scam report synced successfully!');
        } else {
          print('⚠️ Failed to sync report - will retry later');
        }
      } catch (e) {
        print('❌ Error syncing report: $e - will retry later');
      }
    } else {
      print('📱 Offline - report saved locally for later sync');
    }
  }

  static Future<void> saveReportOffline(ScamReportModel report) async {
    // Get current user ID from JWT token
    final keycloakUserId = await JwtService.getCurrentUserId();
    if (keycloakUserId != null) {
      report = report.copyWith(keycloakUserId: keycloakUserId);
    } else {
      // Fallback for device-specific issues
      print('⚠️ Using fallback user ID for offline save');
      report = report.copyWith(
        keycloakUserId: 'device_user_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    print('Saving scam report to local storage: ${report.toJson()}');
    await _box.add(report);
    print('Scam report saved successfully. Box length: ${_box.length}');
  }

  static Future<void> syncReports() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      print('📱 No internet connection - cannot sync');
      return;
    }

    // Initialize reference service before syncing
    print('🔄 Initializing report reference service for sync...');
    await ReportReferenceService.initialize();

    final box = Hive.box<ScamReportModel>('scam_reports');
    final unsyncedReports = box.values
        .where((r) => r.isSynced != true)
        .toList();

    print('🔄 Syncing ${unsyncedReports.length} unsynced scam reports...');

    for (var report in unsyncedReports) {
      try {
        print('📤 Syncing report with type ID: ${report.reportTypeId}');
        final success = await ScamReportService.sendToBackend(report);
        if (success) {
          // Mark as synced
          final key = box.keyAt(box.values.toList().indexOf(report));
          final updated = report.copyWith(isSynced: true);
          await box.put(key, updated);
          print(
            '✅ Successfully synced report with type ID: ${report.reportTypeId}',
          );
        } else {
          print('❌ Failed to sync report with type ID: ${report.reportTypeId}');
        }
      } catch (e) {
        print('❌ Error syncing report with type ID ${report.reportTypeId}: $e');
      }
    }

    print('✅ Sync completed for scam reports');
  }

  static Future<bool> sendToBackend(ScamReportModel report) async {
    try {
      // Get actual ObjectId values from reference service
      final reportCategoryId = ReportReferenceService.getReportCategoryId(
        'scam',
      );

      print('🔄 Using ObjectId values for scam report:');
      print('  - reportCategoryId: $reportCategoryId');
      print(
        '  - reportTypeId: ${report.reportTypeId} (from selected dropdown)',
      );
      print('  - alertLevels: ${report.alertLevels} (from user selection)');

      // Prepare data with actual ObjectId values
      final reportData = {
        'reportCategoryId': reportCategoryId.isNotEmpty
            ? reportCategoryId
            : (report.reportCategoryId ?? 'scam_category_id'),
        'reportTypeId': report.reportTypeId ?? 'scam_type_id',
        'alertLevels': report.alertLevels ?? '',
        'severity':
            report.alertLevels ??
            '', // Also send as severity for backend compatibility
        'phoneNumber': report.phoneNumber ?? '',
        'email': report.email ?? '',
        'website': report.website ?? '',
        'description': report.description ?? '',
        'createdAt':
            report.createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updatedAt':
            report.updatedAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'keycloackUserId':
            report.keycloakUserId ?? 'anonymous_user', // Fallback for no auth
        'name': report.name ?? 'Scam Report',
        'screenshots': report.screenshots ?? [],
        'documents': report.documents ?? [],
        'voiceMessages': report.voiceMessages ?? [], // Scam reports don't typically have voice files
      };

      print('📤 Sending scam report to backend...');
      print('📤 Report data: ${jsonEncode(reportData)}');
      print('🔍 Final alert level being sent: ${reportData['alertLevels']}');
      print('🔍 Original report alert level: ${report.alertLevels}');
      print('🔍 Report ID: ${report.id}');
      print(
        '🔍 Alert level in reportData type: ${reportData['alertLevels'].runtimeType}',
      );
      print(
        '🔍 Alert level in reportData is null: ${reportData['alertLevels'] == null}',
      );
      print(
        '🔍 Alert level in reportData is empty: ${(reportData['alertLevels'] as String?)?.isEmpty}',
      );
      print('🔍 Full reportData keys: ${reportData.keys.toList()}');
      print('🔍 Full reportData values: ${reportData.values.toList()}');
      print('🔍 Alert level in report object: ${report.alertLevels}');
      print('🔍 Alert level type in report: ${report.alertLevels.runtimeType}');
      print('🔍 Alert level is null in report: ${report.alertLevels == null}');
      print(
        '🔍 Alert level is empty in report: ${report.alertLevels?.isEmpty}',
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.mainBaseUrl}/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(reportData),
      );

      print('📥 Send to backend response status: ${response.statusCode}');
      print('📥 Send to backend response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Scam report sent successfully!');
        return true;
      } else {
        print('❌ Scam report failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending scam report to backend: $e');
      return false;
    }
  }

  static Future<void> updateReport(ScamReportModel report) async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    await box.put(report.id, report);
  }

  static List<ScamReportModel> getLocalReports() {
    print('Getting local scam reports. Box length: ${_box.length}');
    final reports = _box.values.toList();
    print('Retrieved ${reports.length} scam reports from local storage');
    return reports;
  }

  static Future<void> updateExistingReportsWithKeycloakUserId() async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    final reports = box.values.toList();

    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      if (report.keycloakUserId == null) {
        final keycloakUserId = await JwtService.getCurrentUserId();
        if (keycloakUserId != null) {
          final updatedReport = report.copyWith(keycloakUserId: keycloakUserId);
          final key = box.keyAt(i);
          await box.put(key, updatedReport);
        }
      }
    }
  }

  static Future<void> removeDuplicateReports() async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    final reports = box.values.toList();
    final seenIds = <String>{};
    final toDelete = <int>[];

    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      final uniqueId = '${report.id}_${report.description}_${report.createdAt}';

      if (seenIds.contains(uniqueId)) {
        toDelete.add(i);
      } else {
        seenIds.add(uniqueId);
      }
    }

    // Delete duplicates in reverse order to maintain indices
    for (int i = toDelete.length - 1; i >= 0; i--) {
      final key = box.keyAt(toDelete[i]);
      await box.delete(key);
    }

    print('Removed ${toDelete.length} duplicate scam reports');
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
