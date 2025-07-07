import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/scam_report_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:security_alert/config/api_config.dart';

class ThreadDatabaseListPage extends StatefulWidget {
  final String searchQuery;
  final String? selectedType;
  final String? selectedSeverity;

  const ThreadDatabaseListPage({
    Key? key,
    required this.searchQuery,
    this.selectedType,
    this.selectedSeverity,
  }) : super(key: key);

  @override
  State<ThreadDatabaseListPage> createState() => _ThreadDatabaseListPageState();
}

class _ThreadDatabaseListPageState extends State<ThreadDatabaseListPage> {
  Color severityColor(String severity) {
    switch (severity) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _manualSync(int index, ScamReportModel report) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    if (!isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No internet connection.')));
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing report...'),
          duration: Duration(seconds: 2),
        ),
      );

      final url = Uri.parse('${ApiConfig.baseUrl}scam_reports');
      print('🔗 Thread DB: Attempting to sync report to: $url');
      print(
        '📤 Thread DB: Report data: ${jsonEncode({'title': report.title, 'description': report.description, 'type': report.type, 'severity': report.severity, 'date': report.date.toIso8601String()})}',
      );

      // Send to backend
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'reportId': report.id, // Send Flutter-generated ID
          'title': report.title,
          'description': report.description,
          'type': report.type,
          'severity': report.severity,
          'date': report.date.toIso8601String(),
          'phone': report.phone ?? '',
          'email': report.email ?? '',
          'website': report.website ?? '',
        }),
      );

      print('📥 Thread DB: Response status: ${response.statusCode}');
      print('📥 Thread DB: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final box = Hive.box<ScamReportModel>('scam_reports');
        final key = box.keyAt(index);
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
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to sync with server. Status: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('💥 Thread DB: Error syncing report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ScamReportModel>('scam_reports');
    List<ScamReportModel> reportsFromHive = box.values.toList();

    // Apply filters
    if (widget.searchQuery.isNotEmpty) {
      reportsFromHive = reportsFromHive
          .where(
            (r) =>
                r.title.toLowerCase().contains(
                  widget.searchQuery.toLowerCase(),
                ) ||
                r.description.toLowerCase().contains(
                  widget.searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }
    if (widget.selectedType != null && widget.selectedType!.isNotEmpty) {
      reportsFromHive = reportsFromHive
          .where((r) => r.type == widget.selectedType)
          .toList();
    }
    if (widget.selectedSeverity != null &&
        widget.selectedSeverity!.isNotEmpty) {
      reportsFromHive = reportsFromHive
          .where((r) => r.severity == widget.selectedSeverity)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thread Database'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'All Reported Records:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Threads Found: ${reportsFromHive.length}',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: reportsFromHive.length,
              itemBuilder: (context, i) {
                final report = reportsFromHive[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: severityColor(report.severity),
                      child: Icon(Icons.warning, color: Colors.white),
                    ),
                    title: Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor(
                              report.severity,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            report.severity,
                            style: TextStyle(
                              color: severityColor(report.severity),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        report.isSynced
                            ? Icon(Icons.cloud_done, color: Colors.green)
                            : IconButton(
                                icon: Icon(Icons.sync, color: Colors.orange),
                                tooltip: 'Sync now',
                                onPressed: () => _manualSync(i, report),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
