import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/scam_report_model.dart';
import '../config/api_config.dart';

class ScamRemoteService {
  Future<bool> sendReport(
    ScamReportModel report, {
    List<File>? screenshots,
    List<File>? documents,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}scam_reports');
      print('🔗 Attempting to send report to: $url');

      // Create multipart request for file uploads
      var request = http.MultipartRequest('POST', url);

      // Add basic report data
      request.fields['reportId'] = report.id; // Send Flutter-generated ID
      request.fields['title'] = report.title;
      request.fields['description'] = report.description;
      request.fields['type'] = report.type;
      request.fields['severity'] = report.severity;
      request.fields['date'] = report.date.toIso8601String();
      request.fields['phone'] = report.phone ?? '';
      request.fields['email'] = report.email ?? '';
      request.fields['website'] = report.website ?? '';

      // Add file paths as JSON
      if (report.screenshotPaths.isNotEmpty) {
        request.fields['screenshotPaths'] = jsonEncode(report.screenshotPaths);
      }
      if (report.documentPaths.isNotEmpty) {
        request.fields['documentPaths'] = jsonEncode(report.documentPaths);
      }

      // Add screenshots
      if (screenshots != null && screenshots.isNotEmpty) {
        for (int i = 0; i < screenshots.length; i++) {
          final file = screenshots[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'screenshots',
            stream,
            length,
            filename: 'screenshot_$i.jpg',
          );
          request.files.add(multipartFile);
        }
      }

      // Add documents
      if (documents != null && documents.isNotEmpty) {
        for (int i = 0; i < documents.length; i++) {
          final file = documents[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'documents',
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      print('📤 Report data: ${request.fields}');
      print('📤 Files to upload: ${request.files.length} files');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Report sent successfully: $responseBody');
        return true;
      } else {
        print(
          '❌ Failed to send report. Status: ${response.statusCode}, Body: $responseBody',
        );
        return false;
      }
    } catch (e) {
      print('💥 Error sending report: $e');
      return false;
    }
  }

  Future<List<ScamReportModel>> fetchReports() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}scam_reports');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data
            .map(
              (e) => ScamReportModel(
                id:
                    e['_id'] ??
                    e['id'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                title: e['title'] ?? '',
                description: e['description'] ?? '',
                type: e['type'] ?? '',
                severity: e['severity'] ?? 'Medium',
                date: DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
                isSynced: true,
              ),
            )
            .toList();
      } else {
        print('Failed to fetch reports. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }
}
