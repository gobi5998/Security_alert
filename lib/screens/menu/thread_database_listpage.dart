import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/scam_report_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:security_alert/config/api_config.dart';
import '../scam/scam_report_service.dart';
import '../../services/api_service.dart';

// changes for GET
// api service page
// thread databaselist page

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
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> backendThreads = [];
  bool isLoadingBackend = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadBackendThreads();
  }

  Future<void> _loadBackendThreads({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        isLoadingMore = true;
        currentPage++;
      });
    } else {
      setState(() {
        isLoadingBackend = true;
        currentPage = 1;
        backendThreads.clear();
      });
    }

    try {
      final reports = await _apiService.getReportsFromBackend(
        search: widget.searchQuery,
        type: widget.selectedType,
        severity: widget.selectedSeverity,
        page: currentPage,
        limit: 50, // Increased limit
      );

      setState(() {
        if (loadMore) {
          backendThreads.addAll(reports);
          isLoadingMore = false;
        } else {
          backendThreads = reports;
          isLoadingBackend = false;
        }

        // Check if we have more data
        hasMoreData = reports.length >= 50;
      });
    } catch (e) {
      print('Error loading backend reports: $e');
      setState(() {
        if (loadMore) {
          isLoadingMore = false;
        } else {
          isLoadingBackend = false;
        }
      });
    }
  }

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
      ).showSnackBar(SnackBar(content: Text('No internet connection.')));
      return;
    }

    try {
      // Use the centralized service to sync the report
      bool success = await ScamReportService.sendToBackend(report);

      if (success) {
        // Update the report as synced in the local database
        final box = Hive.box<ScamReportModel>('scam_reports');
        final key = box.keyAt(index);
        final syncedReport = ScamReportModel(
          id: report.id,
          description: report.description,
          alertLevels: report.alertLevels,
          email: report.email,
          phoneNumber: report.phoneNumber,
          website: report.website,
          createdAt: report.createdAt,
          updatedAt: report.updatedAt,
          reportCategoryId: report.reportCategoryId,
          reportTypeId: report.reportTypeId,
        );
        await box.put(key, syncedReport);
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Report synced successfully!')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to sync with server.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error syncing report: $e')));
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
            (r) => (r.description ?? '').toLowerCase().contains(
              widget.searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }
    if (widget.selectedType != null && widget.selectedType!.isNotEmpty) {
      reportsFromHive = reportsFromHive
          .where(
            (r) => false,
          ) // No type field, so filter out all or adjust as needed
          .toList();
    }
    if (widget.selectedSeverity != null &&
        widget.selectedSeverity!.isNotEmpty) {
      reportsFromHive = reportsFromHive
          .where((r) => (r.alertLevels ?? '') == widget.selectedSeverity)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thread Database'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadBackendThreads),
        ],
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Threads Found: ${reportsFromHive.length + backendThreads.length}',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                if (isLoadingBackend)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBackendThreads,
              child: ListView(
                children: [
                  // Local threads section
                  if (reportsFromHive.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Local Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    ...reportsFromHive.map(
                      (report) => _buildLocalThreadCard(report),
                    ),
                  ],

                  // Backend threads section
                  if (backendThreads.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Backend Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    ...backendThreads.map(
                      (thread) => _buildBackendThreadCard(thread),
                    ),

                    // Load More button
                    if (hasMoreData)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: isLoadingMore
                                ? null
                                : () => _loadBackendThreads(loadMore: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: isLoadingMore
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Loading...'),
                                    ],
                                  )
                                : const Text('Load More'),
                          ),
                        ),
                      ),
                  ],

                  // Loading indicator
                  if (isLoadingBackend)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalThreadCard(ScamReportModel report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severityColor(report.alertLevels ?? ''),
          child: Icon(Icons.warning, color: Colors.white),
        ),
        title: Text(
          report.description ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          report.description ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor(report.alertLevels ?? '').withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report.alertLevels ?? '',
                style: TextStyle(
                  color: severityColor(report.alertLevels ?? ''),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            (report.isSynced != true)
                ? IconButton(
                    icon: Icon(Icons.sync, color: Colors.orange),
                    tooltip: 'Sync now',
                    onPressed: () => _manualSync(0, report),
                  )
                : Icon(Icons.cloud_done, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendThreadCard(Map<String, dynamic> thread) {
    // Determine severity color and icon based on alertLevels
    Color severityColor;
    IconData iconData;

    String? alertLevel = thread['alertLevels']?.toString();

    switch (alertLevel?.toLowerCase()) {
      case 'critical':
      case 'high':
        severityColor = Colors.red;
        iconData = Icons.warning;
        break;
      case 'medium':
        severityColor = Colors.orange;
        iconData = Icons.info;
        break;
      case 'low':
        severityColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      default:
        severityColor = Colors.grey;
        iconData = Icons.help;
    }

    // Parse date from createdAt
    DateTime? reportDate;
    try {
      String? dateStr = thread['createdAt']?.toString();
      if (dateStr != null) {
        reportDate = DateTime.parse(dateStr);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Get description and create title from it
    String description = thread['description']?.toString() ?? '';

    // If description is empty, try to create one from other fields
    if (description.isEmpty) {
      String website = thread['website']?.toString() ?? '';
      String email = thread['email']?.toString() ?? '';

      if (website.isNotEmpty) {
        description = 'Reported website: $website';
      } else if (email.isNotEmpty) {
        description = 'Reported by: $email';
      } else {
        description = 'Report submitted';
      }
    }

    String title = description.length > 25
        ? '${description.substring(0, 25)}...'
        : description;

    // Get reported by from email
    String reportedBy = thread['email']?.toString() ?? 'System User';

    // Get type based on alertLevels
    String type = alertLevel ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Left side - Circular icon
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: severityColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white, size: 20),
            ),

            const SizedBox(width: 12),

            // Main content - More compact
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Description
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Reported by and date in smaller text
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Reported by: ${reportedBy.length > 20 ? '${reportedBy.substring(0, 20)}...' : reportedBy}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 1),

                  // Date
                  Text(
                    reportDate != null
                        ? '${reportDate.day}/${reportDate.month}/${reportDate.year}'
                        : 'Unknown date',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right side - Colored tag (smaller)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: severityColor.withOpacity(0.3)),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: severityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
