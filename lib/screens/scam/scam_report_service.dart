import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/scam_report_model.dart';

class ScamReportService {
  static final _box = Hive.box('scam_reports');

  static Future<void> saveReport(Map<String, dynamic> report) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      // Try to send to backend
      bool success = await sendToBackend(report);
      if (!success) {
        await _box.add(report);
      }
    } else {
      await _box.add(report);
    }
  }

  static Future<void> syncReports() async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    final reports = box.values.toList();
    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      if (!report.isSynced) {
        // Replace with your actual backend API endpoint and payload
        final response = await http.post(
          Uri.parse('https://your-backend-url/api/scam-reports'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': report.title,
            'description': report.description,
            'type': report.type,
            'severity': report.severity,
            'date': report.date.toIso8601String(),
            // Add other fields as needed
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Update as synced
          final key = box.keyAt(i);
          final syncedReport = ScamReportModel(
            id: report.id,
            title: report.title,
            description: report.description,
            type: report.type,
            severity: report.severity,
            date: report.date,
            isSynced: true,
          );
          await box.put(key, syncedReport);
        }
      }
    }
  }

  static Future<bool> sendToBackend(Map<String, dynamic> report) async {
    // TODO: Implement your API call here
    // Return true if successful, false otherwise
    return true;
  }

  static List<Map<String, dynamic>> getLocalReports() {
    return _box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
