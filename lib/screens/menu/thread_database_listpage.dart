import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:security_alert/screens/dashboard_page.dart';
import 'package:security_alert/screens/menu/theard_database.dart';
import '../../models/scam_report_model.dart';
import '../../models/fraud_report_model.dart';
import '../../models/malware_report_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../scam/scam_report_service.dart';
import '../Fraud/fraud_report_service.dart';
import '../malware/malware_report_service.dart';
import '../../services/api_service.dart';

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
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _filteredReports = [];
  Set<int> syncingIndexes = {};
  Map<String, String> _typeIdToName = {}; // Cache for type ID to name mapping
  Map<String, String> _categoryIdToName = {}; // Cache for category ID to name mapping

  @override
  void initState() {
    super.initState();
    print('ThreadDatabaseListPage initialized with:');
    print('- searchQuery: "${widget.searchQuery}"');
    print('- selectedType: "${widget.selectedType}"');
    print('- selectedSeverity: "${widget.selectedSeverity}"');
    print('- scamTypeId: "${widget.scamTypeId}"');
    _loadTypeNames();
    _loadCategoryNames();
    _loadFilteredReports();
  }

  Future<void> _loadFilteredReports() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Fetch all reports from backend API
      List<Map<String, dynamic>> allReports = [];

      print('Fetching reports from backend API...');

      try {
        // Fetch all reports from backend
        final response = await _apiService.fetchAllReports();
        print('Backend API response: $response');

        if (response != null && response is List) {
          allReports = List<Map<String, dynamic>>.from(response);
          print('Successfully fetched ${allReports.length} reports from backend');

          // Debug: Print first report structure
          if (allReports.isNotEmpty) {
            print('First report structure:');
            allReports.first.forEach((key, value) {
              print('  $key: $value (${value.runtimeType})');
            });
          }

          // Store reports locally for offline access
          await _storeReportsLocally(allReports);
        } else {
          print('Invalid response format from backend');
          // Fallback to local data if backend fails
          allReports = await _getLocalReports();
        }
      } catch (e) {
        print('Error fetching from backend: $e');
        // Fallback to local data if backend fails
        allReports = await _getLocalReports();
      }

      // Apply filters
      List<Map<String, dynamic>> filteredReports = allReports;

      print('Total reports before filtering: ${allReports.length}');
      print('Available reports:');
      for (var report in allReports) {
        print('- ID: ${report['id']}, Category: ${report['reportCategoryId']}, Type: ${report['reportTypeId']}, Severity: ${report['alertLevels']}');
      }

      // If no filters are applied, show all reports
      bool hasFilters = widget.searchQuery.isNotEmpty ||
          widget.scamTypeId.isNotEmpty ||
          (widget.selectedType != null && widget.selectedType!.isNotEmpty) ||
          (widget.selectedSeverity != null && widget.selectedSeverity!.isNotEmpty);

      if (!hasFilters) {
        print('No filters applied, showing all reports');
        if (mounted) {
          setState(() {
            _filteredReports = allReports;
            _isLoading = false;
          });
        }
        return;
      }

      // Search filter
      if (widget.searchQuery.isNotEmpty) {
        filteredReports = filteredReports.where((report) {
          final description = report['description']?.toString().toLowerCase() ?? '';
          final email = report['email']?.toString().toLowerCase() ?? '';
          final phone = report['phoneNumber']?.toString().toLowerCase() ?? '';
          final website = report['website']?.toString().toLowerCase() ?? '';
          final searchTerm = widget.searchQuery.toLowerCase();

          return description.contains(searchTerm) ||
              email.contains(searchTerm) ||
              phone.contains(searchTerm) ||
              website.contains(searchTerm);
        }).toList();
        print('After search filter: ${filteredReports.length} reports');
      }

      // Category filter
      if (widget.scamTypeId.isNotEmpty) {
        print('Applying category filter: ${widget.scamTypeId}');
        filteredReports = filteredReports.where((report) {
          final cat = report['reportCategoryId'];
          String? catId;

          if (cat is Map) {
            catId = cat['_id']?.toString() ?? cat['id']?.toString();
          } else {
            catId = cat?.toString();
          }

          final matches = catId == widget.scamTypeId;
          print('Checking report ${report['_id'] ?? report['id']}: category "$catId" matches "${widget.scamTypeId}" = $matches');
          return matches;
        }).toList();
        print('After category filter: ${filteredReports.length} reports');
      }

      // Type filter
      if (widget.selectedType != null && widget.selectedType!.isNotEmpty) {
        print('Applying type filter: ${widget.selectedType}');
        filteredReports = filteredReports.where((report) {
          final type = report['reportTypeId'];
          String? typeId;

          if (type is Map) {
            typeId = type['_id']?.toString() ?? type['id']?.toString();
          } else {
            typeId = type?.toString();
          }

          final matches = typeId == widget.selectedType;
          print('Checking report ${report['_id'] ?? report['id']}: type "$typeId" matches "${widget.selectedType}" = $matches');
          return matches;
        }).toList();
        print('After type filter: ${filteredReports.length} reports');
      }

      // Severity filter
      if (widget.selectedSeverity != null && widget.selectedSeverity!.isNotEmpty) {
        print('Applying severity filter: ${widget.selectedSeverity}');
        filteredReports = filteredReports.where((report) {
          final alertLevels = report['alertLevels']?.toString().toLowerCase();
          final selectedSeverity = widget.selectedSeverity!.toLowerCase();
          final matches = alertLevels == selectedSeverity;
          print('Checking report ${report['_id'] ?? report['id']}: severity "$alertLevels" matches "$selectedSeverity" = $matches');
          return matches;
        }).toList();
        print('After severity filter: ${filteredReports.length} reports');
      }

      if (mounted) {
        setState(() {
          _filteredReports = filteredReports;
          _isLoading = false;
        });
      }

      print('Filtered reports count: ${_filteredReports.length}');
      print('Applied filters:');
      print('- Search: ${widget.searchQuery}');
      print('- Category: ${widget.scamTypeId}');
      print('- Type: ${widget.selectedType}');
      print('- Severity: ${widget.selectedSeverity}');

      // Debug print for available IDs
      print('Available Category IDs:');
      for (var report in filteredReports) {
        final cat = report['reportCategoryId'];
        final type = report['reportTypeId'];
        print('Report: ${report['_id'] ?? report['id']}, category: ${cat is Map ? cat['_id'] : cat}, type: ${type is Map ? type['_id'] : type}');
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reports: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Fallback method to get local reports if backend fails
  Future<List<Map<String, dynamic>>> _getLocalReports() async {
    List<Map<String, dynamic>> allReports = [];

    // Get scam reports
    final scamBox = Hive.box<ScamReportModel>('scam_reports');
    print('Scam reports box length: ${scamBox.length}');
    for (var report in scamBox.values) {
      print('Scam report: ID=${report.id}, Category=${report.reportCategoryId}, Type=${report.reportTypeId}, Severity=${report.alertLevels}');
      allReports.add({
        'id': report.id,
        'description': report.description,
        'alertLevels': report.alertLevels,
        'email': report.email,
        'phoneNumber': report.phoneNumber,
        'website': report.website,
        'createdAt': report.createdAt,
        'updatedAt': report.updatedAt,
        'reportCategoryId': report.reportCategoryId,
        'reportTypeId': report.reportTypeId,
        'type': 'scam',
        'isSynced': report.isSynced,
      });
    }

    // Get fraud reports
    final fraudBox = Hive.box<FraudReportModel>('fraud_reports');
    print('Fraud reports box length: ${fraudBox.length}');
    for (var report in fraudBox.values) {
      print('Fraud report: ID=${report.id}, Category=${report.reportCategoryId}, Type=${report.reportTypeId}, Severity=${report.alertLevels}');
      allReports.add({
        'id': report.id,
        'description': report.description ?? report.name ?? 'Fraud Report',
        'alertLevels': report.alertLevels,
        'email': report.email,
        'phoneNumber': report.phoneNumber,
        'website': report.website,
        'createdAt': report.createdAt,
        'updatedAt': report.updatedAt,
        'reportCategoryId': report.reportCategoryId,
        'reportTypeId': report.reportTypeId,
        'name': report.name,
        'type': 'fraud',
        'isSynced': report.isSynced,
      });
    }

    // Get malware reports
    final malwareBox = Hive.box<MalwareReportModel>('malware_reports');
    print('Malware reports box length: ${malwareBox.length}');
    for (var report in malwareBox.values) {
      print('Malware report: ID=${report.id}, Severity=${report.alertSeverityLevel}');
      allReports.add({
        'id': report.id,
        'description': report.malwareType ?? 'Malware Report',
        'alertLevels': report.alertSeverityLevel,
        'email': null,
        'phoneNumber': null,
        'website': null,
        'createdAt': report.date,
        'updatedAt': report.date,
        'reportCategoryId': null,
        'reportTypeId': null,
        'type': 'malware',
        'isSynced': report.isSynced,
        'fileName': report.fileName,
        'malwareType': report.malwareType,
        'infectedDeviceType': report.infectedDeviceType,
        'operatingSystem': report.operatingSystem,
        'detectionMethod': report.detectionMethod,
        'location': report.location,
        'name': report.name,
        'systemAffected': report.systemAffected,
      });
    }

    return allReports;
  }

  // Store reports locally in Hive boxes
  Future<void> _storeReportsLocally(List<Map<String, dynamic>> reports) async {
    try {
      print('=== STORING REPORTS LOCALLY ===');
      print('Total reports to store: ${reports.length}');

      if (reports.isEmpty) {
        print('No reports to store');
        return;
      }

      // Debug: Print first few reports
      for (int i = 0; i < reports.length && i < 3; i++) {
        print('Report $i: ${reports[i]}');
      }

      // Separate reports by type
      List<Map<String, dynamic>> scamReports = [];
      List<Map<String, dynamic>> fraudReports = [];
      List<Map<String, dynamic>> malwareReports = [];

      for (var report in reports) {
        final type = report['type']?.toString().toLowerCase();
        print('Processing report type: $type');

        switch (type) {
          case 'scam':
            scamReports.add(report);
            break;
          case 'fraud':
            fraudReports.add(report);
            break;
          case 'malware':
            malwareReports.add(report);
            break;
          default:
            // Try to determine type from other fields
            if (report['malwareType'] != null || report['fileName'] != null) {
              malwareReports.add(report);
              print('Classified as malware based on fields');
            } else if (report['reportCategoryId'] != null && report['reportTypeId'] != null) {
              // Default to scam if we have category and type
              scamReports.add(report);
              print('Classified as scam based on fields');
            } else {
              // Default to fraud for unknown types
              fraudReports.add(report);
              print('Classified as fraud (default)');
            }
        }
      }

      // Store scam reports
      if (scamReports.isNotEmpty) {
        print('Storing ${scamReports.length} scam reports...');
        final scamBox = Hive.box<ScamReportModel>('scam_reports');
        await scamBox.clear(); // Clear existing data
        print('Cleared existing scam reports');

        int storedCount = 0;
        for (var report in scamReports) {
          try {
            print('Processing scam report: ${report['_id'] ?? report['id']}');

            // Extract category and type information
            String? categoryId;
            String? typeId;

            // Handle different data structures for category and type
            final categoryObj = report['reportCategoryId'];
            final typeObj = report['reportTypeId'];

            if (categoryObj is Map) {
              categoryId = categoryObj['_id']?.toString() ?? categoryObj['id']?.toString();
            } else {
              categoryId = categoryObj?.toString();
            }

            if (typeObj is Map) {
              typeId = typeObj['_id']?.toString() ?? typeObj['id']?.toString();
            } else {
              typeId = typeObj?.toString();
            }

            print('Extracted category ID: $categoryId, type ID: $typeId');

            final scamReport = ScamReportModel(
              id: report['_id']?.toString() ?? report['id']?.toString() ?? '',
              description: report['description']?.toString() ?? '',
              alertLevels: report['alertLevels']?.toString() ?? 'medium',
              email: report['email']?.toString(),
              phoneNumber: report['phoneNumber']?.toString(),
              website: report['website']?.toString(),
              createdAt: report['createdAt'] != null
                  ? (report['createdAt'] is DateTime
                      ? report['createdAt']
                      : DateTime.parse(report['createdAt'].toString()))
                  : DateTime.now(),
              updatedAt: report['updatedAt'] != null
                  ? (report['updatedAt'] is DateTime
                      ? report['updatedAt']
                      : DateTime.parse(report['updatedAt'].toString()))
                  : DateTime.now(),
              reportCategoryId: categoryId,
              reportTypeId: typeId,
              isSynced: true, // Mark as synced since it came from backend
            );
            await scamBox.add(scamReport);
            storedCount++;
            print('Successfully stored scam report ${scamReport.id} with category: ${scamReport.reportCategoryId}, type: ${scamReport.reportTypeId}');
          } catch (e) {
            print('Error storing scam report: $e');
            print('Report data: $report');
          }
        }
        print('Successfully stored $storedCount/${scamReports.length} scam reports locally');
      }

      // Store fraud reports
      if (fraudReports.isNotEmpty) {
        print('Storing ${fraudReports.length} fraud reports...');
        final fraudBox = Hive.box<FraudReportModel>('fraud_reports');
        await fraudBox.clear(); // Clear existing data
        print('Cleared existing fraud reports');

        int storedCount = 0;
        for (var report in fraudReports) {
          try {
            print('Processing fraud report: ${report['_id'] ?? report['id']}');

            // Extract category and type information
            String? categoryId;
            String? typeId;

            // Handle different data structures for category and type
            final categoryObj = report['reportCategoryId'];
            final typeObj = report['reportTypeId'];

            if (categoryObj is Map) {
              categoryId = categoryObj['_id']?.toString() ?? categoryObj['id']?.toString();
            } else {
              categoryId = categoryObj?.toString();
            }

            if (typeObj is Map) {
              typeId = typeObj['_id']?.toString() ?? typeObj['id']?.toString();
            } else {
              typeId = typeObj?.toString();
            }

            print('Extracted category ID: $categoryId, type ID: $typeId');

            final fraudReport = FraudReportModel(
              id: report['_id']?.toString() ?? report['id']?.toString() ?? '',
              description: report['description']?.toString() ?? '',
              alertLevels: report['alertLevels']?.toString() ?? 'medium',
              email: report['email']?.toString(),
              phoneNumber: report['phoneNumber']?.toString(),
              website: report['website']?.toString(),
              createdAt: report['createdAt'] != null
                  ? (report['createdAt'] is DateTime
                      ? report['createdAt']
                      : DateTime.parse(report['createdAt'].toString()))
                  : DateTime.now(),
              updatedAt: report['updatedAt'] != null
                  ? (report['updatedAt'] is DateTime
                      ? report['updatedAt']
                      : DateTime.parse(report['updatedAt'].toString()))
                  : DateTime.now(),
              reportCategoryId: categoryId,
              reportTypeId: typeId,
              name: report['name']?.toString() ?? 'Fraud Report',
              isSynced: true, // Mark as synced since it came from backend
            );
            await fraudBox.add(fraudReport);
            storedCount++;
            print('Successfully stored fraud report ${fraudReport.id} with category: ${fraudReport.reportCategoryId}, type: ${fraudReport.reportTypeId}');
          } catch (e) {
            print('Error storing fraud report: $e');
            print('Report data: $report');
          }
        }
        print('Successfully stored $storedCount/${fraudReports.length} fraud reports locally');
      }

      // Store malware reports
      if (malwareReports.isNotEmpty) {
        print('Storing ${malwareReports.length} malware reports...');
        final malwareBox = Hive.box<MalwareReportModel>('malware_reports');
        await malwareBox.clear(); // Clear existing data
        print('Cleared existing malware reports');

        int storedCount = 0;
        for (var report in malwareReports) {
          try {
            print('Processing malware report: ${report['_id'] ?? report['id']}');

            // Extract category and type information
            String? categoryId;
            String? typeId;

            // Handle different data structures for category and type
            final categoryObj = report['reportCategoryId'];
            final typeObj = report['reportTypeId'];

            if (categoryObj is Map) {
              categoryId = categoryObj['_id']?.toString() ?? categoryObj['id']?.toString();
            } else {
              categoryId = categoryObj?.toString();
            }

            if (typeObj is Map) {
              typeId = typeObj['_id']?.toString() ?? typeObj['id']?.toString();
            } else {
              typeId = typeObj?.toString();
            }

            print('Extracted category ID: $categoryId, type ID: $typeId');

            final malwareReport = MalwareReportModel(
              id: report['_id']?.toString() ?? report['id']?.toString() ?? '',
              malwareType: report['malwareType']?.toString() ?? 'Unknown Malware',
              infectedDeviceType: report['infectedDeviceType']?.toString() ?? 'Unknown Device',
              operatingSystem: report['operatingSystem']?.toString() ?? 'Unknown OS',
              detectionMethod: report['detectionMethod']?.toString() ?? 'Unknown Method',
              location: report['location']?.toString() ?? 'Unknown Location',
              fileName: report['fileName']?.toString() ?? '',
              name: report['name']?.toString() ?? 'Malware Report',
              systemAffected: report['systemAffected']?.toString() ?? 'Unknown System',
              alertSeverityLevel: report['alertLevels']?.toString() ?? report['alertSeverityLevel']?.toString() ?? 'medium',
              date: report['createdAt'] != null
                  ? (report['createdAt'] is DateTime
                      ? report['createdAt']
                      : DateTime.parse(report['createdAt'].toString()))
                  : DateTime.now(),
              isSynced: true, // Mark as synced since it came from backend
            );
            await malwareBox.add(malwareReport);
            storedCount++;
            print('Successfully stored malware report ${malwareReport.id}');
          } catch (e) {
            print('Error storing malware report: $e');
            print('Report data: $report');
          }
        }
        print('Successfully stored $storedCount/${malwareReports.length} malware reports locally');
      }

      print('Successfully stored all reports locally');

      // Verify storage
      await _verifyLocalStorage();
    } catch (e) {
      print('Error storing reports locally: $e');
    }
  }

  // Verify that reports were stored correctly
  Future<void> _verifyLocalStorage() async {
    try {
      final scamBox = Hive.box<ScamReportModel>('scam_reports');
      final fraudBox = Hive.box<FraudReportModel>('fraud_reports');
      final malwareBox = Hive.box<MalwareReportModel>('malware_reports');

      print('=== STORAGE VERIFICATION ===');
      print('Scam reports in storage: ${scamBox.length}');
      print('Fraud reports in storage: ${fraudBox.length}');
      print('Malware reports in storage: ${malwareBox.length}');
      print('Total reports in storage: ${scamBox.length + fraudBox.length + malwareBox.length}');

      // Print first few reports from each box
      if (scamBox.isNotEmpty) {
        final firstScam = scamBox.values.first;
        print('First scam report: ${firstScam.id} - Category: ${firstScam.reportCategoryId}, Type: ${firstScam.reportTypeId}');
      }
      if (fraudBox.isNotEmpty) {
        final firstFraud = fraudBox.values.first;
        print('First fraud report: ${firstFraud.id} - Category: ${firstFraud.reportCategoryId}, Type: ${firstFraud.reportTypeId}');
      }
      if (malwareBox.isNotEmpty) {
        final firstMalware = malwareBox.values.first;
        print('First malware report: ${firstMalware.id}');
      }
    } catch (e) {
      print('Error verifying local storage: $e');
    }
  }

  // Test backend connectivity
  Future<void> _testBackendConnectivity() async {
    try {
      print('=== TESTING BACKEND CONNECTIVITY ===');
      
      // Test basic connectivity
      final response = await _apiService.fetchAllReports();
      print('Backend test result: ${response.length} reports fetched');
      
      // Test backend endpoints
      await _apiService.testBackendEndpoints();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backend test: ${response.length} reports found'),
            backgroundColor: response.isNotEmpty ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Backend connectivity test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backend test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create and sync test reports to backend
  Future<void> _createTestReports() async {
    try {
      print('=== CREATING TEST REPORTS ===');
      
      // Create a test scam report
      final testScamReport = ScamReportModel(
        id: 'test_scam_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Test scam report for debugging',
        alertLevels: 'high',
        email: 'test@scam.com',
        phoneNumber: '1234567890',
        website: 'testscam.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reportCategoryId: 'test_category_id',
        reportTypeId: 'test_type_id',
        isSynced: false,
      );

      // Create a test fraud report
      final testFraudReport = FraudReportModel(
        id: 'test_fraud_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Test fraud report for debugging',
        alertLevels: 'medium',
        email: 'test@fraud.com',
        phoneNumber: '0987654321',
        website: 'testfraud.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reportCategoryId: 'test_category_id',
        reportTypeId: 'test_type_id',
        name: 'Test Fraud Report',
        isSynced: false,
      );

      // Create a test malware report
      final testMalwareReport = MalwareReportModel(
        id: 'test_malware_${DateTime.now().millisecondsSinceEpoch}',
        malwareType: 'Test Malware',
        infectedDeviceType: 'Test Device',
        operatingSystem: 'Test OS',
        detectionMethod: 'Test Method',
        location: 'Test Location',
        fileName: 'test_file.exe',
        name: 'Test Malware Report',
        systemAffected: 'Test System',
        alertSeverityLevel: 'critical',
        date: DateTime.now(),
        isSynced: false,
      );

      // Store reports locally first
      final scamBox = Hive.box<ScamReportModel>('scam_reports');
      final fraudBox = Hive.box<FraudReportModel>('fraud_reports');
      final malwareBox = Hive.box<MalwareReportModel>('malware_reports');

      await scamBox.add(testScamReport);
      await fraudBox.add(testFraudReport);
      await malwareBox.add(testMalwareReport);

      print('Created test reports locally');

      // Try to sync them to backend
      bool scamSynced = await ScamReportService.sendToBackend(testScamReport);
      bool fraudSynced = await FraudReportService.sendToBackend(testFraudReport);
      bool malwareSynced = await MalwareReportService.sendToBackend(testMalwareReport);

      print('Sync results: Scam=$scamSynced, Fraud=$fraudSynced, Malware=$malwareSynced');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test reports created. Sync: Scam=$scamSynced, Fraud=$fraudSynced, Malware=$malwareSynced'),
            backgroundColor: (scamSynced || fraudSynced || malwareSynced) ? Colors.green : Colors.orange,
          ),
        );
      }

      // Reload the data
      await _loadFilteredReports();

    } catch (e) {
      print('Error creating test reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating test reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  String _getReportTypeDisplay(Map<String, dynamic> report) {
    // Try to get the type from the report data
    final type = report['type']?.toString().toLowerCase();
    final reportType = report['reportType']?.toString();
    final category = report['reportCategory']?.toString();
    final description = report['description']?.toString();

    // Check if we have a specific report type
    if (reportType != null && reportType.isNotEmpty) {
      return reportType;
    }

    // Check if we have a category
    if (category != null && category.isNotEmpty) {
      return category;
    }

    // Check if we have a description that looks like a type
    if (description != null && description.isNotEmpty && description.length < 50) {
      return description;
    }

    // Try to get both category and type names
    final categoryId = report['reportCategoryId']?.toString() ??
        report['categoryId']?.toString() ??
        report['category']?.toString();
    final typeId = report['reportTypeId']?.toString() ??
        report['typeId']?.toString() ??
        report['type']?.toString();

    String? categoryName;
    String? typeName;

    if (categoryId != null && categoryId.isNotEmpty) {
      categoryName = _resolveCategoryName(categoryId);
    }

    if (typeId != null && typeId.isNotEmpty) {
      typeName = _resolveTypeName(typeId);
    }

    // If we have both category and type names, combine them
    if (categoryName != null && typeName != null) {
      return '$categoryName - $typeName';
    }

    // If we have only category name
    if (categoryName != null) {
      return categoryName;
    }

    // If we have only type name
    if (typeName != null) {
      return typeName;
    }

    // Fallback to type-based naming
    switch (type) {
      case 'scam':
        return 'Report Scam';
      case 'fraud':
        return 'Report Fraud';
      case 'malware':
        return 'Report Malware';
      default:
      // Try to construct a name from available data
        if (type != null && type.isNotEmpty) {
          return 'Report ${type.substring(0, 1).toUpperCase()}${type.substring(1)}';
        }
        return 'Security Report';
    }
  }

  Future<void> _loadTypeNames() async {
    try {
      print('Loading type names from API...');
      final types = await _apiService.fetchReportTypes();
      print('Loaded ${types.length} types from API');

      _typeIdToName.clear();
      for (var type in types) {
        final id = type['_id']?.toString() ?? type['id']?.toString();
        final name = type['name']?.toString() ??
            type['typeName']?.toString() ??
            type['title']?.toString() ??
            type['description']?.toString() ??
            'Type ${id ?? 'Unknown'}';

        if (id != null) {
          _typeIdToName[id] = name;
          print('Type mapping: $id -> $name');
        }
      }
      print('Type name cache built with ${_typeIdToName.length} entries');
    } catch (e) {
      print('Error loading type names: $e');
    }
  }

  Future<void> _loadCategoryNames() async {
    try {
      print('Loading category names from API...');
      final categories = await _apiService.fetchReportCategories();
      print('Loaded ${categories.length} categories from API');

      _categoryIdToName.clear();
      for (var category in categories) {
        final id = category['_id']?.toString() ?? category['id']?.toString();
        final name = category['name']?.toString() ??
            category['categoryName']?.toString() ??
            category['title']?.toString() ??
            'Category ${id ?? 'Unknown'}';

        if (id != null) {
          _categoryIdToName[id] = name;
          print('Category mapping: $id -> $name');
        }
      }
      print('Category name cache built with ${_categoryIdToName.length} entries');
    } catch (e) {
      print('Error loading category names: $e');
    }
  }

  String? _resolveTypeName(String typeId) {
    return _typeIdToName[typeId];
  }

  String? _resolveCategoryName(String categoryId) {
    return _categoryIdToName[categoryId];
  }

  bool _hasEvidence(Map<String, dynamic> report) {
    // Check if report has any evidence fields
    final type = report['type'];

    if (type == 'malware') {
      // For malware reports, check for file evidence
      return (report['fileName'] != null && report['fileName'].toString().isNotEmpty) ||
          (report['malwareType'] != null && report['malwareType'].toString().isNotEmpty);
    } else {
      // For scam and fraud reports, check for contact evidence
      return (report['email'] != null && report['email'].toString().isNotEmpty) ||
          (report['phoneNumber'] != null && report['phoneNumber'].toString().isNotEmpty) ||
          (report['website'] != null && report['website'].toString().isNotEmpty);
    }
  }

  String _getReportStatus(Map<String, dynamic> report) {
    // Check multiple status indicators
    final isSynced = report['isSynced'];
    final status = report['status']?.toString().toLowerCase();
    final synced = report['synced'];
    final uploaded = report['uploaded'];
    final completed = report['completed'];

    // If we have a specific status field
    if (status != null && status.isNotEmpty) {
      if (status == 'completed' || status == 'synced' || status == 'uploaded') {
        return 'Completed';
      } else if (status == 'pending' || status == 'processing') {
        return 'Pending';
      }
    }

    // Check boolean fields
    if (isSynced == true || synced == true || uploaded == true || completed == true) {
      return 'Completed';
    }

    // Check if report has an ID from backend (indicates it's uploaded)
    final hasBackendId = report['_id'] != null || report['id'] != null;
    if (hasBackendId && (report['createdAt'] != null || report['updatedAt'] != null)) {
      return 'Completed';
    }

    // Default to pending if no clear indication
    return 'Pending';
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Unknown time';

    try {
      DateTime createdDate;
      if (createdAt is String) {
        createdDate = DateTime.parse(createdAt);
      } else if (createdAt is DateTime) {
        createdDate = createdAt;
      } else {
        return 'Unknown time';
      }

      final now = DateTime.now();
      final difference = now.difference(createdDate);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  Future<void> _manualSync(int index, Map<String, dynamic> report) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection.')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        syncingIndexes.add(index);
      });
    }

    try {
      bool success = false;

      switch (report['type']) {
        case 'scam':
          success = await ScamReportService.sendToBackend(
            ScamReportModel(
              id: report['id'],
              description: report['description'],
              alertLevels: report['alertLevels'],
              email: report['email'],
              phoneNumber: report['phoneNumber'],
              website: report['website'],
              createdAt: report['createdAt'],
              updatedAt: report['updatedAt'],
              reportCategoryId: report['reportCategoryId'],
              reportTypeId: report['reportTypeId'],
            ),
          );
          break;
        case 'fraud':
          success = await FraudReportService.sendToBackend(
            FraudReportModel(
              id: report['id'],
              description: report['description'],
              alertLevels: report['alertLevels'],
              email: report['email'],
              phoneNumber: report['phoneNumber'],
              website: report['website'],
              createdAt: report['createdAt'],
              updatedAt: report['updatedAt'],
              reportCategoryId: report['reportCategoryId'],
              reportTypeId: report['reportTypeId'],
              name: report['name'],
            ),
          );
          break;
        case 'malware':
          success = await MalwareReportService.sendToBackend(
            MalwareReportModel(
              id: report['id'],
              name: report['name'],
              alertSeverityLevel: report['alertSeverityLevel'],
              date: report['date'],
              detectionMethod: report['detectionMethod'],
              fileName: report['fileName'],
              infectedDeviceType: report['infectedDeviceType'],
              location: report['location'],
              malwareType: report['malwareType'],
              operatingSystem: report['operatingSystem'],
              systemAffected: report['systemAffected'],
            ),
          );
          break;
      }

      if (success) {
        // Update the report as synced
        if (mounted) {
          setState(() {
            _filteredReports[index]['isSynced'] = true;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${report['type']} report synced successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync with server.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          syncingIndexes.remove(index);
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DashboardPage(),
          ),
        );}, icon: Icon(Icons.arrow_back)),
        title: const Text('Thread Database'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadFilteredReports,
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _testBackendConnectivity,
            tooltip: 'Test Backend',
          ),
          IconButton(
            icon: Icon(Icons.add_circle),
            onPressed: _createTestReports,
            tooltip: 'Create Test Reports',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Summary
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All  Reported Records:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // if (widget.searchQuery.isNotEmpty)
                      //   Text('Search: "${widget.searchQuery}"', style: TextStyle(fontSize: 12)),
                      // if (widget.scamTypeId.isNotEmpty)
                      //   Text('Category: ${widget.scamTypeId}', style: TextStyle(fontSize: 12)),
                      // if (widget.selectedType != null && widget.selectedType!.isNotEmpty)
                      //   Text('Type: ${widget.selectedType}', style: TextStyle(fontSize: 12)),
                      // if (widget.selectedSeverity != null && widget.selectedSeverity!.isNotEmpty)
                      //   Text('Severity: ${widget.selectedSeverity}', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ThreadDatabaseFilterPage(  ))),
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
          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Threads Found: ${_filteredReports.length}',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Error Message
          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade600),
                    onPressed: () {
                      if (mounted) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                ],
              ),
            ),
          // Loading or Results
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                ? SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No reports found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Debug section to show all available reports
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug: Available Reports',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text('Total reports in database: ${_filteredReports.length}'),
                        SizedBox(height: 8),
                        Text('Applied filters:'),
                        Text('- Search: "${widget.searchQuery}"'),
                        Text('- Category: "${widget.scamTypeId}"'),
                        Text('- Type: "${widget.selectedType}"'),
                        Text('- Severity: "${widget.selectedSeverity}"'),
                        SizedBox(height: 8),
                        Text('Hive Box Status:'),
                        Text('- Scam reports: ${Hive.box<ScamReportModel>('scam_reports').length}'),
                        Text('- Fraud reports: ${Hive.box<FraudReportModel>('fraud_reports').length}'),
                        Text('- Malware reports: ${Hive.box<MalwareReportModel>('malware_reports').length}'),
                      ],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                final reportType = _getReportTypeDisplay(report);
                final hasEvidence = _hasEvidence(report);
                final status = _getReportStatus(report);
                final timeAgo = _getTimeAgo(report['createdAt']);

                final categoryObj = report['reportCategoryId'];
                final typeObj = report['reportTypeId'];

                final categoryName = categoryObj is Map ? categoryObj['name'] ?? '' : '';
                final typeName = typeObj is Map ? typeObj['name'] ?? '' : '';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Report Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Report Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Report Type
                            Text(
                              ' $categoryName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: $typeName',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            // Description
                            Text(
                              report['description'] ?? 'No description available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Tags Row
                            Row(
                              children: [
                                // Severity Tag
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: severityColor(report['alertLevels'] ?? ''),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    report['alertLevels'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Evidence Tag
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hasEvidence ? Colors.blue : Colors.grey[600],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    hasEvidence ? 'Has Evidence' : 'No Evidence',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right Side - Time and Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Time Ago
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Status
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status == 'Pending')
                                Icon(
                                  Icons.sync,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: status == 'Completed' ? Colors.green : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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