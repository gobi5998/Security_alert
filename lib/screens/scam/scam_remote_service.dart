import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/api_config.dart';
import '../../models/scam_report_model.dart';


class ScamRemoteService {
  Future<bool> sendReport(ScamReportModel report) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/scam-reports');
      
      // Prepare the request body with all report data
      final requestBody = {
        'title': report.title,
        'description': report.description,
        'type': report.type,
        'severity': report.severity,
        'email': report.email,
        'phone': report.phone,
        'website': report.website,
        'date': report.date.toIso8601String(),
        'id': report.id, // Include the local ID for reference
      };

      print('Sending report to: $url');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Try to parse the response to get the server-generated ID
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['_id'] != null) {
            print('Report created successfully with server ID: ${responseData['_id']}');
          }
        } catch (e) {
          print('Could not parse response body: $e');
        }
        return true;
      } else {
        print('Failed to send report. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception while sending report: $e');
      return false;
    }
  }

  Future<List<ScamReportModel>> fetchReports() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/scam-reports');
      print('Fetching reports from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );
      
      print('Fetch response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        print('Fetched ${data.length} reports from server');
        
        return data
            .map(
              (e) => ScamReportModel(
                id: e['_id'] ?? e['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: e['title'] ?? '',
                description: e['description'] ?? '',
                type: e['type'] ?? '',
                severity: e['severity'] ?? 'Medium',
                date: DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
                isSynced: true,
                email: e['email'] ?? '',
                phone: e['phone'] ?? '',
                website: e['website'] ?? '',
              ),
            )
            .toList();
      } else {
        print('Failed to fetch reports. Status: ${response.statusCode}, Body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception while fetching reports: $e');
      return [];
    }
  }
}
