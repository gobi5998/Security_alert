// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import '../../models/scam_report_model.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:security_alert/config/api_config.dart';
// import '../scam/scam_report_service.dart';
//
// class ThreadDatabaseListPage extends StatefulWidget {
//   final String searchQuery;
//   final String? selectedType;
//   final String? selectedSeverity;
//   final String scamTypeId;
//
//   const ThreadDatabaseListPage({
//     Key? key,
//     required this.searchQuery,
//     this.selectedType,
//     this.selectedSeverity,  required this.scamTypeId,
//   }) : super(key: key);
//
//   @override
//   State<ThreadDatabaseListPage> createState() => _ThreadDatabaseListPageState();
// }
//
// class _ThreadDatabaseListPageState extends State<ThreadDatabaseListPage> {
//   final List<Map<String, dynamic>> scamTypes = [];
//
//   Color severityColor(String severity) {
//     switch (severity) {
//       case 'Low':
//         return Colors.green;
//       case 'Medium':
//         return Colors.orange;
//       case 'High':
//         return Colors.red;
//       case 'Critical':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   Future<void> _manualSync(int index, ScamReportModel report) async {
//     final connectivityResult = await Connectivity().checkConnectivity();
//     final isOnline = connectivityResult != ConnectivityResult.none;
//     if (!isOnline) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('No internet connection.')));
//       return;
//     }
//
//     try {
//       // Use the centralized service to sync the report
//       bool success = await ScamReportService.sendToBackend(report);
//
//       if (success) {
//         // Update the report as synced in the local database
//         final box = Hive.box<ScamReportModel>('scam_reports');
//         final key = box.keyAt(index);
//         final syncedReport = ScamReportModel(
//           id: report.id,
//
//           description: report.description,
//
//           alertLevels: report.alertLevels,
//           email: report.email,
//           phoneNumber: report.phoneNumber,
//           website: report.website,
//           createdAt: report.createdAt,
//           updatedAt: report.updatedAt,
//            reportCategoryId: report.reportCategoryId, reportTypeId: report.reportTypeId,
//         );
//         await box.put(key, syncedReport);
//         setState(() {});
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Report synced successfully!')));
//       } else {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Failed to sync with server.')));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error syncing report: $e')));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final box = Hive.box<ScamReportModel>('scam_reports');
//     List<ScamReportModel> reportsFromHive = box.values.toList();
//
//     // Apply filters
//     if (widget.searchQuery.isNotEmpty) {
//       reportsFromHive = reportsFromHive
//           .where(
//             (r) =>
//               (r.description ?? '').toLowerCase().contains(widget.searchQuery.toLowerCase()),
//           )
//           .toList();
//     }
//     if (widget.selectedType != null && widget.selectedType!.isNotEmpty) {
//       reportsFromHive = reportsFromHive
//           .where((r) => false) // No type field, so filter out all or adjust as needed
//           .toList();
//     }
//     if (widget.selectedSeverity != null &&
//         widget.selectedSeverity!.isNotEmpty) {
//       reportsFromHive = reportsFromHive
//           .where((r) => (r.alertLevels ?? '') == widget.selectedSeverity)
//           .toList();
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Thread Database'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             color: Colors.grey[200],
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               children: [
//                 const Expanded(
//                   child: Text(
//                     'All Reported Records:',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {},
//                   child: const Text('Filter'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[300],
//                     foregroundColor: Colors.black,
//                     elevation: 0,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text(
//               'Threads Found: ${reportsFromHive.length}',
//               style: TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: reportsFromHive.length,
//               itemBuilder: (context, i) {
//                 final report = reportsFromHive[i];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 4,
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: severityColor(report.alertLevels ?? ''),
//                       child: Icon(Icons.warning, color: Colors.white),
//                     ),
//                     title:Text(report.description ?? '',),
//                     subtitle: Text(
//                       report.description ?? '',
//                       maxLines: 2,
//                       style: TextStyle(fontSize:10),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: severityColor(
//                               report.alertLevels ?? '',
//                             ).withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             report.alertLevels ?? '',
//                             style: TextStyle(
//                               color: severityColor(report.alertLevels ?? ''),
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         (report.isSynced != true)
//                             ? IconButton(
//                                 icon: Icon(Icons.sync, color: Colors.orange),
//                                 tooltip: 'Sync now',
//                                 onPressed: () => _manualSync(i, report),
//                               )
//                             : Icon(Icons.cloud_done, color: Colors.green),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/scam_report_model.dart';
import '../../models/fraud_report_model.dart';
import '../../models/malware_report_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../scam/scam_report_service.dart';
import '../Fraud/fraud_report_service.dart';
import '../malware/malware_report_service.dart';

class ThreadDatabaseListPage extends StatefulWidget {
  final String searchQuery;
  final String? selectedType;
  final String? selectedSeverity;
  final String scamTypeId;

  const ThreadDatabaseListPage({
    Key? key,
    required this.searchQuery,
    this.selectedType,
    this.selectedSeverity,
    required this.scamTypeId,
  }) : super(key: key);

  @override
  State<ThreadDatabaseListPage> createState() => _ThreadDatabaseListPageState();
}

class _ThreadDatabaseListPageState extends State<ThreadDatabaseListPage> {
  final List<Map<String, dynamic>> scamTypes = [];
  Set<int> syncingIndexes = {};

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

  Future<void> _manualSyncScam(int index, ScamReportModel report) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No internet connection.')));
      return;
    }

    setState(() {
      syncingIndexes.add(index);
    });

    try {
      bool success = await ScamReportService.sendToBackend(report);

      if (success) {
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
          isSynced: true,
        );

        await box.put(key, syncedReport);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scam report synced successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync with server.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error syncing report: $e')));
    } finally {
      setState(() {
        syncingIndexes.remove(index);
      });
    }
  }

  Future<void> _manualSyncFraud(int index, FraudReportModel report) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No internet connection.')));
      return;
    }

    setState(() {
      syncingIndexes.add(index);
    });

    try {
      bool success = await FraudReportService.sendToBackend(report);

      if (success) {
        final box = Hive.box<FraudReportModel>('fraud_reports');
        final key = box.keyAt(index);

        final syncedReport = FraudReportModel(
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
          name: report.name,
          isSynced: true,
        );

        await box.put(key, syncedReport);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fraud report synced successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync with server.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error syncing report: $e')));
    } finally {
      setState(() {
        syncingIndexes.remove(index);
      });
    }
  }

  Future<void> _manualSyncMalware(int index, MalwareReportModel report) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No internet connection.')));
      return;
    }

    setState(() {
      syncingIndexes.add(index);
    });

    try {
      bool success = await MalwareReportService.sendToBackend(report);

      if (success) {
        final box = Hive.box<MalwareReportModel>('malware_reports');
        final key = box.keyAt(index);

        final syncedReport = report.copyWith(isSynced: true);
        await box.put(key, syncedReport);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Malware report synced successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync with server.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error syncing report: $e')));
    } finally {
      setState(() {
        syncingIndexes.remove(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get scam, fraud, and malware reports
    final scamBox = Hive.box<ScamReportModel>('scam_reports');
    final fraudBox = Hive.box<FraudReportModel>('fraud_reports');
    final malwareBox = Hive.box<MalwareReportModel>('malware_reports');

    List<ScamReportModel> scamReports = scamBox.values.toList();
    List<FraudReportModel> fraudReports = fraudBox.values.toList();
    List<MalwareReportModel> malwareReports = malwareBox.values.toList();

    // Combine reports into a unified list
    List<Map<String, dynamic>> allReports = [];

    // Add scam reports with type indicator
    for (int i = 0; i < scamReports.length; i++) {
      allReports.add({'type': 'scam', 'index': i, 'report': scamReports[i]});
    }

    // Add fraud reports with type indicator
    for (int i = 0; i < fraudReports.length; i++) {
      allReports.add({'type': 'fraud', 'index': i, 'report': fraudReports[i]});
    }

    // Add malware reports with type indicator
    for (int i = 0; i < malwareReports.length; i++) {
      allReports.add({
        'type': 'malware',
        'index': i,
        'report': malwareReports[i],
      });
    }

    // Sort by creation date (newest first) and remove duplicates
    allReports.sort((a, b) {
      DateTime aDate;
      DateTime bDate;

      // Handle different date field names for different report types
      if (a['report'] is MalwareReportModel) {
        aDate = (a['report'] as MalwareReportModel).date;
      } else {
        aDate = a['report'].createdAt ?? DateTime.now();
      }

      if (b['report'] is MalwareReportModel) {
        bDate = (b['report'] as MalwareReportModel).date;
      } else {
        bDate = b['report'].createdAt ?? DateTime.now();
      }

      return bDate.compareTo(aDate); // Newest first
    });

    // Remove duplicates based on ID and type
    final seenIds = <String>{};
    allReports = allReports.where((item) {
      final report = item['report'];
      final reportType = item['type'];
      String uniqueId;

      // Handle different date field names for different report types
      if (report is MalwareReportModel) {
        uniqueId = '${report.id}_${report.name}_${report.date}';
      } else {
        uniqueId = '${report.id}_$reportType';
      }

      if (seenIds.contains(uniqueId)) {
        return false;
      }
      seenIds.add(uniqueId);
      return true;
    }).toList();

    // Apply filters
    if (widget.searchQuery.isNotEmpty) {
      allReports = allReports.where((item) {
        final report = item['report'];

        // Handle different field names for different report types
        if (report is MalwareReportModel) {
          return (report.name ?? '').toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          );
        } else {
          return (report.description ?? '').toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          );
        }
      }).toList();
    }

    if (widget.selectedSeverity != null &&
        widget.selectedSeverity!.isNotEmpty) {
      allReports = allReports.where((item) {
        final report = item['report'];

        // Handle different severity field names for different report types
        if (report is MalwareReportModel) {
          return (report.alertSeverityLevel ?? '') == widget.selectedSeverity;
        } else {
          return (report.alertLevels ?? '') == widget.selectedSeverity;
        }
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thread Database'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  child: const Text('Filter'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Threads Found: ${allReports.length}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allReports.length,
              itemBuilder: (context, i) {
                final item = allReports[i];
                final report = item['report'];
                final reportType = item['type'];
                final reportIndex = item['index'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: severityColor(
                        report is MalwareReportModel
                            ? (report as MalwareReportModel)
                                      .alertSeverityLevel ??
                                  ''
                            : report.alertLevels ?? '',
                      ),
                      child: Icon(
                        reportType == 'fraud'
                            ? Icons.warning
                            : reportType == 'malware'
                            ? Icons.security
                            : Icons.warning,
                        color: Colors.white,
                      ),
                    ),
                    title: Text('Type: ${reportType.toUpperCase()}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report is MalwareReportModel
                              ? (report as MalwareReportModel).name ?? ''
                              : report.description ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (reportType == 'fraud' && report.name != null)
                          Text(
                            'Name: ${report.name}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 8,
                        //     vertical: 4,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: severityColor(
                        //       report.alertLevels ?? '',
                        //     ).withOpacity(0.1),
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: Text(
                        //     report.alertLevels ?? '',
                        //     style: TextStyle(
                        //       color: severityColor(report.alertLevels ?? ''),
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(width: 8),
                        if (report.isSynced == true)
                          const Icon(Icons.cloud_done, color: Colors.green)
                        else if (syncingIndexes.contains(i))
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.sync, color: Colors.orange),
                            tooltip: 'Sync now',
                            onPressed: () {
                              if (reportType == 'scam') {
                                _manualSyncScam(reportIndex, report);
                              } else if (reportType == 'fraud') {
                                _manualSyncFraud(reportIndex, report);
                              } else if (reportType == 'malware') {
                                _manualSyncMalware(reportIndex, report);
                              }
                            },
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
