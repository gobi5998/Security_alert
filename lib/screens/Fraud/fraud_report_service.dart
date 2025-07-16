import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/fraud_report_model.dart';
import '../../models/scam_report_model.dart';
import '../../config/api_config.dart';

class FraudReportService {
  static final _box = Hive.box<FraudReportModel>('fraud_reports');

  static Future<void> saveReport(FraudReportModel report) async {
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

  static Future<void> syncReports() async {
    final box = Hive.box<FraudReportModel>('fraud_reports');
    final reports = box.values.toList();
    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      if (!report.isSynced) {
        try {
          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}fraud-reports'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'title': report.title,
              'name': report.name,
              'type': report.type,
              'email': report.email,
              'phone': report.phone,
              'website': report.website, // Fixed: was report.type
              'severity': report.severity,

              'date': report.date.toIso8601String(),
              'id': report.id,
            }),
          );

          print('Sync response status: ${response.statusCode}');
          print('Sync response body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Update as synced
            final key = box.keyAt(i);
            final syncedReport = FraudReportModel(
              id: report.id,
              title: report.title,
              name: report.name,
              type: report.type,
              severity: report.severity,
              date: report.date,
              email: report.email,
              phone: report.phone,
              website: report.website,
              isSynced: true,
            );
            await box.put(key, syncedReport);
            print('Successfully synced report: ${report.id}');
          } else {
            print('Failed to sync report. Status: ${response.statusCode}, Body: ${response.body}');
          }
        } catch (e) {
          print('Error syncing report: $e');
        }
      }
    }
  }

  static Future<bool> sendToBackend(FraudReportModel report) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}fraud-reports'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'title': report.title,
          'name': report.name,
          'type': report.type,
          'email': report.email,
          'phone': report.phone,
          'website': report.website,
          'severity': report.severity,
          'date': report.date.toIso8601String(),
          'id': report.id,
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

  static List<FraudReportModel> getLocalReports() {
    return _box.values.toList();
  }
}
