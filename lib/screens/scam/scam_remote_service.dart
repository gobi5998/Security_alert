import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/api_config.dart';
import '../../models/scam_report_model.dart';


class ScamRemoteService {
  Future<bool> sendReport(ScamReportModel report) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/scam-reports');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': report.title,
        'description': report.description,
        'type': report.type,
        'severity': report.severity,
        'date': report.date.toIso8601String(),
      }),
    );
    return response.statusCode == 201;
  }

  Future<List<ScamReportModel>> fetchReports() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/scam-reports');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data
          .map(
            (e) => ScamReportModel(
              id: e['_id'],
              title: e['title'],
              description: e['description'],
              type: e['type'],
              severity: e['severity'],
              date: DateTime.parse(e['date']),
              isSynced: true,
            ),
          )
          .toList();
    }
    return [];
  }
}
