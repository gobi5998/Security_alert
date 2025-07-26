import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:security_alert/screens/dashboard_page.dart';
import 'package:security_alert/screens/drawer/theard_database.dart';
import '../../models/filter_model.dart';
import '../../models/scam_report_model.dart';
import '../../models/fraud_report_model.dart';
import '../../models/malware_report_model.dart';
import '../../models/report_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../scam/scam_report_service.dart';
import '../Fraud/fraud_report_service.dart';
import '../malware/malware_report_service.dart';
import '../../services/api_service.dart';
import 'report_detail_view.dart';

class ThreadDatabaseListPage extends StatefulWidget {
  final String searchQuery;
  final String? selectedType;
  final String? selectedSeverity;
  final String scamTypeId;
  final bool hasSearchQuery;
  final bool hasSelectedType;
  final bool hasSelectedSeverity;
  final bool hasSelectedCategory;

  const ThreadDatabaseListPage({
    Key? key,
    required this.searchQuery,
    this.selectedType,
    this.selectedSeverity,
    required this.scamTypeId,
    this.hasSearchQuery = false,
    this.hasSelectedType = false,
    this.hasSelectedSeverity = false,
    this.hasSelectedCategory = false,
  }) : super(key: key);

  @override
  State<ThreadDatabaseListPage> createState() => _ThreadDatabaseListPageState();
}

class _ThreadDatabaseListPageState extends State<ThreadDatabaseListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isLoadingMore = false; // New: for loading more data
  bool _hasMoreData = true; // New: check if more data is available
  String? _errorMessage;
  List<Map<String, dynamic>> _filteredReports = [];
  List<ReportModel> _typedReports = []; // New typed reports list
  Set<int> syncingIndexes = {};
  Map<String, String> _typeIdToName = {}; // Cache for type ID to name mapping
  Map<String, String> _categoryIdToName = {}; // Cache for category ID to name mapping

  // New: Pagination variables
  int _currentPage = 1;
  final int _pageSize = 20; // Number of items per page
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print('ThreadDatabaseListPage initialized with:');
    print('- searchQuery: "${widget.searchQuery}"');
    print('- selectedType: "${widget.selectedType}"');
    print('- selectedSeverity: "${widget.selectedSeverity}"');
    print('- scamTypeId: "${widget.scamTypeId}"');
    print('- hasSearchQuery: ${widget.hasSearchQuery}');
    print('- hasSelectedType: ${widget.hasSelectedType}');
    print('- hasSelectedSeverity: ${widget.hasSelectedSeverity}');
    print('- hasSelectedCategory: ${widget.hasSelectedCategory}');

    // New: Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);

    // Load category and type names with enhanced method
    _loadCategoryAndTypeNames();
    _loadFilteredReports();

    // Refresh the UI after a short delay to ensure category/type names are loaded
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // New: Dispose scroll controller
    _scrollController.dispose();
    super.dispose();
  }

  // New: Scroll listener for infinite scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  // New: Method to check if we should load more data
  bool _shouldLoadMore() {
    return !_isLoadingMore &&
        _hasMoreData &&
        _scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200;
  }

  // New: Method to load more data
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    // Check network connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _handleError(
        'No internet connection. Cannot load more data.',
        isWarning: true,
      );
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      print('Loading more data, page: $_currentPage');

      List<Map<String, dynamic>> newReports = [];

      // Check if we have any filters applied
      bool hasFilters =
          widget.hasSearchQuery ||
          widget.hasSelectedCategory ||
          widget.hasSelectedType ||
          widget.hasSelectedSeverity;

      if (hasFilters) {
        // Use the new complex filter method with pagination
        newReports = await _apiService.getReportsWithComplexFilter(
          searchQuery: widget.hasSearchQuery ? widget.searchQuery : null,
          categoryIds:
              widget.hasSelectedCategory && widget.scamTypeId.isNotEmpty
              ? [widget.scamTypeId]
              : null,
          typeIds: widget.hasSelectedType && widget.selectedType != null
              ? [widget.selectedType!]
              : null,
          severityLevels:
              widget.hasSelectedSeverity && widget.selectedSeverity != null
              ? [widget.selectedSeverity!]
              : null,
          page: _currentPage,
          limit: _pageSize,
        );
      } else {
        // No filters, get all reports with pagination
        final filter = ReportsFilter(page: _currentPage, limit: _pageSize);
        newReports = await _apiService.fetchReportsWithFilter(filter);
      }

      print('Loaded ${newReports.length} new reports for page $_currentPage');

      if (newReports.isNotEmpty) {
        // Debug: Print first report structure to understand data format
        print('First new report structure:');
        final firstReport = newReports.first;
        firstReport.forEach((key, value) {
          print('  $key: $value (${value.runtimeType})');
        });

        // Deduplicate reports to prevent repeated data
        final existingIds = _filteredReports
            .map((r) => r['_id'] ?? r['id'])
            .toSet();
        final uniqueNewReports = newReports.where((report) {
          final reportId = report['_id'] ?? report['id'];
          return reportId != null && !existingIds.contains(reportId);
        }).toList();

        print('After deduplication: ${uniqueNewReports.length} unique reports');

        if (uniqueNewReports.isNotEmpty) {
          // Add new reports to existing lists
          _filteredReports.addAll(uniqueNewReports);

          // Safely convert to ReportModel objects
          final newTypedReports = <ReportModel>[];
          for (var report in uniqueNewReports) {
            try {
              final reportModel = _safeConvertToReportModel(report);
              newTypedReports.add(reportModel);
            } catch (e) {
              print('Error converting report to ReportModel: $e');
              print('Report data: $report');
              // Continue with other reports even if one fails
            }
          }
          _typedReports.addAll(newTypedReports);

          // Check if we have more data (if we got less than page size, we're at the end)
          if (newReports.length < _pageSize) {
            _hasMoreData = false;
            print('Reached end of data');
          }
        } else {
          // All new reports were duplicates, check if we should stop
          if (newReports.length < _pageSize) {
            _hasMoreData = false;
            print('Reached end of data (all duplicates)');
          } else if (_isDuplicateData(newReports)) {
            // If we're getting all duplicates and we have a full page, the API might not be paginated correctly
            _hasMoreData = false;
            print('Stopping infinite scroll due to API pagination issues');
            _handleError(
              'API pagination issue detected. Stopping infinite scroll.',
              isWarning: true,
            );
          }
        }
      } else {
        // No more data
        _hasMoreData = false;
        print('No more data available');
      }
    } catch (e) {
      print('Error loading more data: $e');
      _currentPage--; // Revert page number on error
      _handleError('Failed to load more data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // New: Method to handle edge cases and errors
  void _handleError(String message, {bool isWarning = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isWarning ? Colors.orange : Colors.red,
          duration: Duration(seconds: isWarning ? 3 : 5),
        ),
      );
    }
  }

  // New: Method to validate pagination state
  bool _isPaginationValid() {
    return _currentPage > 0 && _pageSize > 0 && !_isLoadingMore;
  }

  // New: Method to safely convert API data to ReportModel
  ReportModel _safeConvertToReportModel(Map<String, dynamic> json) {
    try {
      // First, try to normalize the data structure
      final normalizedJson = _normalizeReportData(json);
      return ReportModel.fromJson(normalizedJson);
    } catch (e) {
      print('Error converting report to ReportModel: $e');
      print('Original report data: $json');

      // Create a fallback ReportModel with available data
      return ReportModel.fromJson({
        'id':
            json['_id'] ??
            json['id'] ??
            'unknown_${DateTime.now().millisecondsSinceEpoch}',
        'description': json['description'] ?? json['name'] ?? 'Unknown Report',
        'alertLevels':
            json['alertLevels'] ?? json['alertSeverityLevel'] ?? 'medium',
        'createdAt':
            json['createdAt'] ??
            json['date'] ??
            DateTime.now().toIso8601String(),
        'email': json['email'],
        'phoneNumber': json['phoneNumber'],
        'website': json['website'],
      });
    }
  }

  // New: Method to normalize report data structure
  Map<String, dynamic> _normalizeReportData(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // Handle nested objects that should be strings
    if (normalized['reportCategoryId'] is Map) {
      final categoryMap = normalized['reportCategoryId'] as Map;
      normalized['reportCategoryId'] =
          categoryMap['_id'] ?? categoryMap['id'] ?? '';
      // Also extract category name if available
      if (categoryMap['name'] != null) {
        normalized['categoryName'] = categoryMap['name'].toString();
      }
    }

    if (normalized['reportTypeId'] is Map) {
      final typeMap = normalized['reportTypeId'] as Map;
      normalized['reportTypeId'] = typeMap['_id'] ?? typeMap['id'] ?? '';
      // Also extract type name if available
      if (typeMap['name'] != null) {
        normalized['typeName'] = typeMap['name'].toString();
      }
    }

    // Ensure required fields exist
    normalized['id'] = normalized['_id'] ?? normalized['id'] ?? 'unknown';
    normalized['description'] =
        normalized['description'] ?? normalized['name'] ?? 'Unknown Report';
    normalized['alertLevels'] =
        normalized['alertLevels'] ??
        normalized['alertSeverityLevel'] ??
        'medium';
    normalized['createdAt'] =
        normalized['createdAt'] ??
        normalized['date'] ??
        DateTime.now().toIso8601String();

    // Mark as synced if it has a backend ID
    if (normalized['_id'] != null) {
      normalized['isSynced'] = true;
    }

    return normalized;
  }

  // New: Method to check if we're getting duplicate data from API
  bool _isDuplicateData(List<Map<String, dynamic>> newReports) {
    if (newReports.isEmpty) return false;

    // Check if all new reports already exist in current list
    final existingIds = _filteredReports
        .map((r) => r['_id'] ?? r['id'])
        .toSet();
    final allDuplicates = newReports.every((report) {
      final reportId = report['_id'] ?? report['id'];
      return reportId != null && existingIds.contains(reportId);
    });

    if (allDuplicates) {
      print(
        'Warning: All new reports are duplicates. API may not be properly paginated.',
      );
    }

    return allDuplicates;
  }

  // New: Method to reset pagination and reload data
  Future<void> _resetAndReload() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
      _filteredReports.clear();
      _typedReports.clear();
    });
    await _loadFilteredReports();
  }

  // New: Method to handle manual refresh
  Future<void> _handleManualRefresh() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refreshing reports...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
    await _resetAndReload();
  }

  Future<void> _loadFilteredReports() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _currentPage = 1; // Reset to first page
          _hasMoreData = true; // Reset has more data flag
        });
      }

      // Try to use the new dynamic API methods first
      List<Map<String, dynamic>> typedReports = [];

      print('Attempting to use new dynamic API methods...');

      try {
        // Check if we have any filters applied
        bool hasFilters =
            widget.hasSearchQuery ||
            widget.hasSelectedCategory ||
            widget.hasSelectedType ||
            widget.hasSelectedSeverity;

        if (hasFilters) {
          // Use the new complex filter method
          typedReports = await _apiService.getReportsWithComplexFilter(
            searchQuery: widget.hasSearchQuery ? widget.searchQuery : null,
            categoryIds:
                widget.hasSelectedCategory && widget.scamTypeId.isNotEmpty
                ? [widget.scamTypeId]
                : null,
            typeIds: widget.hasSelectedType && widget.selectedType != null
                ? [widget.selectedType!]
                : null,
            severityLevels:
                widget.hasSelectedSeverity && widget.selectedSeverity != null
                ? [widget.selectedSeverity!]
                : null,
            page: _currentPage,
            limit: _pageSize,
          );

          print(
            'Used complex filter API, got ${typedReports.length} typed reports',
          );
        } else {
          // No filters, get all reports
          final filter = ReportsFilter(page: _currentPage, limit: _pageSize);
          typedReports = await _apiService.fetchReportsWithFilter(filter);
          print(
            'Used basic filter API, got ${typedReports.length} typed reports',
          );
        }

        // Convert typed reports to the format expected by existing UI
        _filteredReports = typedReports;
        // Convert to ReportModel objects for enhanced features
        _typedReports = typedReports
            .map((json) => _safeConvertToReportModel(json))
            .toList();

        // Check if we have more data
        if (typedReports.length < _pageSize) {
          _hasMoreData = false;
        }

        print(
          'Successfully converted ${typedReports.length} typed reports to UI format',
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        return; // Success with new API, exit early
      } catch (e) {
        print('New API methods failed, falling back to old methods: $e');
        // Continue with old methods as fallback
      }

      // Fallback to old methods (without pagination for now)
      print('Using fallback API methods...');

      // Fetch all reports from backend API
      List<Map<String, dynamic>> allReports = [];

      print('Fetching reports from backend API...');

      try {
        // Fetch all reports from backend
        final response = await _apiService.fetchAllReports();
        print('Backend API response: $response');

        if (response != null && response is List) {
          allReports = List<Map<String, dynamic>>.from(response);
          print(
            'Successfully fetched ${allReports.length} reports from backend',
          );

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
        print(
          '- ID: ${report['id']}, Category: ${report['reportCategoryId']}, Type: ${report['reportTypeId']}, Severity: ${report['alertLevels']}',
        );
      }

      // If no filters are applied, show all reports
      bool hasFilters =
          widget.hasSearchQuery ||
          widget.hasSelectedCategory ||
          widget.hasSelectedType ||
          widget.hasSelectedSeverity;

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
      if (widget.hasSearchQuery && widget.searchQuery.isNotEmpty) {
        filteredReports = filteredReports.where((report) {
          final description =
              report['description']?.toString().toLowerCase() ?? '';
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
      if (widget.hasSelectedCategory && widget.scamTypeId.isNotEmpty) {
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
          print(
            'Checking report ${report['_id'] ?? report['id']}: category "$catId" matches "${widget.scamTypeId}" = $matches',
          );
          return matches;
        }).toList();
        print('After category filter: ${filteredReports.length} reports');
      }

      // Type filter
      if (widget.hasSelectedType &&
          widget.selectedType != null &&
          widget.selectedType!.isNotEmpty) {
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
          print(
            'Checking report ${report['_id'] ?? report['id']}: type "$typeId" matches "${widget.selectedType}" = $matches',
          );
          return matches;
        }).toList();
        print('After type filter: ${filteredReports.length} reports');
      }

      // Severity filter
      if (widget.hasSelectedSeverity &&
          widget.selectedSeverity != null &&
          widget.selectedSeverity!.isNotEmpty) {
        print('Applying severity filter: ${widget.selectedSeverity}');
        filteredReports = filteredReports.where((report) {
          final alertLevels = report['alertLevels']?.toString().toLowerCase();
          final selectedSeverity = widget.selectedSeverity!.toLowerCase();
          final matches = alertLevels == selectedSeverity;
          print(
            'Checking report ${report['_id'] ?? report['id']}: severity "$alertLevels" matches "$selectedSeverity" = $matches',
          );
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
        print(
          'Report: ${report['_id'] ?? report['id']}, category: ${cat is Map ? cat['_id'] : cat}, type: ${type is Map ? type['_id'] : type}',
        );
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
      print(
        'Scam report: ID=${report.id}, Category=${report.reportCategoryId}, Type=${report.reportTypeId}, Severity=${report.alertLevels}',
      );
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
      print(
        'Fraud report: ID=${report.id}, Category=${report.reportCategoryId}, Type=${report.reportTypeId}, Severity=${report.alertLevels}',
      );
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
      print(
        'Malware report: ID=${report.id}, Severity=${report.alertSeverityLevel}',
      );
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
            } else if (report['reportCategoryId'] != null &&
                report['reportTypeId'] != null) {
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
              categoryId =
                  categoryObj['_id']?.toString() ??
                  categoryObj['id']?.toString();
            } else {
              categoryId = categoryObj?.toString();
            }

            if (typeObj is Map) {
              typeId = typeObj['_id']?.toString() ?? typeObj['id']?.toString();
            } else {
              typeId = typeObj?.toString();
            }

            print('Extracted category ID: $categoryId, type ID: $typeId');

            // Extract category and type names if available
            String? categoryName;
            String? typeName;

            final categoryObjForName = report['reportCategoryId'];
            final typeObjForName = report['reportTypeId'];

            if (categoryObjForName is Map) {
              categoryName = categoryObjForName['name']?.toString();
            }
            if (typeObjForName is Map) {
              typeName = typeObjForName['name']?.toString();
            }

            // Also check for direct name fields
            if (categoryName == null) {
              categoryName = report['categoryName']?.toString();
            }
            if (typeName == null) {
              typeName = report['typeName']?.toString();
            }

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
            print(
              'Successfully stored scam report ${scamReport.id} with category: ${scamReport.reportCategoryId}, type: ${scamReport.reportTypeId}',
            );
          } catch (e) {
            print('Error storing scam report: $e');
            print('Report data: $report');
          }
        }
        print(
          'Successfully stored $storedCount/${scamReports.length} scam reports locally',
        );
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
              categoryId =
                  categoryObj['_id']?.toString() ??
                  categoryObj['id']?.toString();
            } else {
              categoryId = categoryObj?.toString();
            }

            if (typeObj is Map) {
              typeId = typeObj['_id']?.toString() ?? typeObj['id']?.toString();
            } else {
              typeId = typeObj?.toString();
            }

            print('Extracted category ID: $categoryId, type ID: $typeId');

            // Extract category and type names if available
            String? categoryName;
            String? typeName;

            final categoryObjForName = report['reportCategoryId'];
            final typeObjForName = report['reportTypeId'];

            if (categoryObjForName is Map) {
              categoryName = categoryObjForName['name']?.toString();
            }
            if (typeObjForName is Map) {
              typeName = typeObjForName['name']?.toString();
            }

            // Also check for direct name fields
            if (categoryName == null) {
              categoryName = report['categoryName']?.toString();
            }
            if (typeName == null) {
              typeName = report['typeName']?.toString();
            }

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
            print(
              'Successfully stored fraud report ${fraudReport.id} with category: ${fraudReport.reportCategoryId}, type: ${fraudReport.reportTypeId}',
            );
          } catch (e) {
            print('Error storing fraud report: $e');
            print('Report data: $report');
          }
        }
        print(
          'Successfully stored $storedCount/${fraudReports.length} fraud reports locally',
        );
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
            print(
              'Processing malware report: ${report['_id'] ?? report['id']}',
            );

            // Extract category and type information
            String? categoryId;
            String? typeId;

            // Handle different data structures for category and type
            final categoryObj = report['reportCategoryId'];
            final typeObj = report['reportTypeId'];

            if (categoryObj is Map) {
              categoryId =
                  categoryObj['_id']?.toString() ??
                  categoryObj['id']?.toString();
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
              malwareType:
                  report['malwareType']?.toString() ?? 'Unknown Malware',
              infectedDeviceType:
                  report['infectedDeviceType']?.toString() ?? 'Unknown Device',
              operatingSystem:
                  report['operatingSystem']?.toString() ?? 'Unknown OS',
              detectionMethod:
                  report['detectionMethod']?.toString() ?? 'Unknown Method',
              location: report['location']?.toString() ?? 'Unknown Location',
              fileName: report['fileName']?.toString() ?? '',
              name: report['name']?.toString() ?? 'Malware Report',
              systemAffected:
                  report['systemAffected']?.toString() ?? 'Unknown System',
              alertSeverityLevel:
                  report['alertLevels']?.toString() ??
                  report['alertSeverityLevel']?.toString() ??
                  'medium',
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
        print(
          'Successfully stored $storedCount/${malwareReports.length} malware reports locally',
        );
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
      print(
        'Total reports in storage: ${scamBox.length + fraudBox.length + malwareBox.length}',
      );

      // Print first few reports from each box
      if (scamBox.isNotEmpty) {
        final firstScam = scamBox.values.first;
        print(
          'First scam report: ${firstScam.id} - Category: ${firstScam.reportCategoryId}, Type: ${firstScam.reportTypeId}',
        );
      }
      if (fraudBox.isNotEmpty) {
        final firstFraud = fraudBox.values.first;
        print(
          'First fraud report: ${firstFraud.id} - Category: ${firstFraud.reportCategoryId}, Type: ${firstFraud.reportTypeId}',
        );
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
      bool fraudSynced = await FraudReportService.sendToBackend(
        testFraudReport,
      );
      bool malwareSynced = await MalwareReportService.sendToBackend(
        testMalwareReport,
      );

      print(
        'Sync results: Scam=$scamSynced, Fraud=$fraudSynced, Malware=$malwareSynced',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test reports created. Sync: Scam=$scamSynced, Fraud=$fraudSynced, Malware=$malwareSynced',
            ),
            backgroundColor: (scamSynced || fraudSynced || malwareSynced)
                ? Colors.green
                : Colors.orange,
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
    // First, check if we have category and type names directly from the report
    final categoryName = report['categoryName']?.toString();
    final typeName = report['typeName']?.toString();

    // If we have both category and type names, combine them
    if (categoryName != null &&
        categoryName.isNotEmpty &&
        typeName != null &&
        typeName.isNotEmpty) {
      return '$categoryName - $typeName';
    }

    // If we have only category name
    if (categoryName != null && categoryName.isNotEmpty) {
      return categoryName;
    }

    // If we have only type name
    if (typeName != null && typeName.isNotEmpty) {
      return typeName;
    }

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
    if (description != null &&
        description.isNotEmpty &&
        description.length < 50) {
      return description;
    }

    // Try to get both category and type names from IDs
    String? categoryId;
    String? typeId;

    // Handle nested objects for category and type IDs
    final categoryObj = report['reportCategoryId'];
    final typeObj = report['reportTypeId'];

    if (categoryObj is Map) {
      categoryId =
          categoryObj['_id']?.toString() ?? categoryObj['id']?.toString();
    } else {
      categoryId = categoryObj?.toString();
    }

    if (typeObj is Map) {
      typeId = typeObj['_id']?.toString() ?? typeObj['id']?.toString();
    } else {
      typeId = typeObj?.toString();
    }

    // Also check for alternative field names
    if (categoryId == null) {
      categoryId =
          report['categoryId']?.toString() ?? report['category']?.toString();
    }
    if (typeId == null) {
      typeId = report['typeId']?.toString() ?? report['type']?.toString();
    }

    String? resolvedCategoryName;
    String? resolvedTypeName;

    if (categoryId != null && categoryId.isNotEmpty) {
      resolvedCategoryName = _resolveCategoryName(categoryId);
    }

    if (typeId != null && typeId.isNotEmpty) {
      resolvedTypeName = _resolveTypeName(typeId);
    }

    // If we have both resolved category and type names, combine them
    if (resolvedCategoryName != null && resolvedTypeName != null) {
      return '$resolvedCategoryName - $resolvedTypeName';
    }

    // If we have only resolved category name
    if (resolvedCategoryName != null) {
      return resolvedCategoryName;
    }

    // If we have only resolved type name
    if (resolvedTypeName != null) {
      return resolvedTypeName;
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
        final name =
            type['name']?.toString() ??
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
        final name =
            category['name']?.toString() ??
            category['categoryName']?.toString() ??
            category['title']?.toString() ??
            'Category ${id ?? 'Unknown'}';

        if (id != null) {
          _categoryIdToName[id] = name;
          print('Category mapping: $id -> $name');
        }
      }
      print(
        'Category name cache built with ${_categoryIdToName.length} entries',
      );
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
      return (report['fileName'] != null &&
              report['fileName'].toString().isNotEmpty) ||
          (report['malwareType'] != null &&
              report['malwareType'].toString().isNotEmpty);
    } else {
      // For scam and fraud reports, check for contact evidence
      return (report['email'] != null &&
              report['email'].toString().isNotEmpty) ||
          (report['phoneNumber'] != null &&
              report['phoneNumber'].toString().isNotEmpty) ||
          (report['website'] != null &&
              report['website'].toString().isNotEmpty);
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
    if (isSynced == true ||
        synced == true ||
        uploaded == true ||
        completed == true) {
      return 'Completed';
    }

    // Check if report has an ID from backend (indicates it's uploaded)
    final hasBackendId = report['_id'] != null || report['id'] != null;
    if (hasBackendId &&
        (report['createdAt'] != null || report['updatedAt'] != null)) {
      return 'Completed';
    }

    // If the report came from backend API (has _id), it's completed
    if (report['_id'] != null) {
      return 'Completed';
    }

    // Check if report has category and type IDs (indicates it's from backend)
    final hasCategoryId = report['reportCategoryId'] != null;
    final hasTypeId = report['reportTypeId'] != null;
    final hasMalwareType = report['malwareType'] != null;
    if (hasCategoryId || hasTypeId || hasMalwareType) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No internet connection.')));
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
          SnackBar(
            content: Text('${report['type']} report synced successfully!'),
          ),
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
      if (mounted) {
        setState(() {
          syncingIndexes.remove(index);
        });
      }
    }
  }

  // New method to test the dynamic API with the exact URL structure
  // Future<void> _testDynamicApi() async {
  //   try {
  //     setState(() {
  //       _isLoading = true;
  //       _errorMessage = null;
  //     });
  //
  //     print('=== TESTING DYNAMIC API WITH EXACT URL ===');
  //
  //     // Test the exact URL structure you provided
  //     final reports = await _apiService.testExactUrlStructure();
  //
  //     print('Dynamic API test result: ${reports.length} reports');
  //
  //     if (reports.isNotEmpty) {
  //       print('First report structure:');
  //       reports.first.forEach((key, value) {
  //         print('  $key: $value (${value.runtimeType})');
  //       });
  //
  //       // Debug: Check category and type structure
  //       final firstReport = reports.first;
  //       print('Category structure: ${firstReport['reportCategoryId']}');
  //       print('Type structure: ${firstReport['reportTypeId']}');
  //
  //       if (firstReport['reportCategoryId'] is Map) {
  //         final categoryMap = firstReport['reportCategoryId'] as Map;
  //         print('Category map keys: ${categoryMap.keys}');
  //         print('Category name: ${categoryMap['name']}');
  //       }
  //
  //       if (firstReport['reportTypeId'] is Map) {
  //         final typeMap = firstReport['reportTypeId'] as Map;
  //         print('Type map keys: ${typeMap.keys}');
  //         print('Type name: ${typeMap['name']}');
  //       }
  //     }
  //
  //     // Convert to UI format
  //     _filteredReports = reports;
  //     _typedReports = reports
  //         .map((json) => ReportModel.fromJson(json))
  //         .toList();
  //
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Dynamic API test: ${reports.length} reports found'),
  //           backgroundColor: reports.isNotEmpty ? Colors.green : Colors.orange,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print('Dynamic API test failed: $e');
  //     if (mounted) {
  //       setState(() {
  //         _errorMessage = 'Dynamic API test failed: $e';
  //         _isLoading = false;
  //       });
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Dynamic API test failed: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  // Enhanced method to load category and type names with better error handling
  Future<void> _loadCategoryAndTypeNames() async {
    try {
      print('Loading category and type names from API...');

      // Load categories
      final categories = await _apiService.fetchReportCategories();
      print('Loaded ${categories.length} categories from API');

      _categoryIdToName.clear();
      for (var category in categories) {
        final id = category['_id']?.toString() ?? category['id']?.toString();
        final name =
            category['name']?.toString() ??
            category['categoryName']?.toString() ??
            category['title']?.toString() ??
            'Category ${id ?? 'Unknown'}';

        if (id != null) {
          _categoryIdToName[id] = name;
          print('Category mapping: $id -> $name');
        }
      }

      // Load types
      final types = await _apiService.fetchReportTypes();
      print('Loaded ${types.length} types from API');

      _typeIdToName.clear();
      for (var type in types) {
        final id = type['_id']?.toString() ?? type['id']?.toString();
        final name =
            type['name']?.toString() ??
            type['typeName']?.toString() ??
            type['title']?.toString() ??
            'Type ${id ?? 'Unknown'}';

        if (id != null) {
          _typeIdToName[id] = name;
          print('Type mapping: $id -> $name');
        }
      }

      print(
        'Category name cache built with ${_categoryIdToName.length} entries',
      );
      print('Type name cache built with ${_typeIdToName.length} entries');

      // Debug: Print all available mappings
      print('Available category mappings:');
      _categoryIdToName.forEach((id, name) {
        print('  $id -> $name');
      });

      print('Available type mappings:');
      _typeIdToName.forEach((id, name) {
        print('  $id -> $name');
      });

      // Refresh the UI to show the resolved names
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading category and type names: $e');
    }
  }

  // New method to use complex filtering with pagination
  Future<void> _useComplexFilter() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1; // Reset to first page
        _hasMoreData = true; // Reset has more data flag
      });

      print('=== USING COMPLEX FILTER ===');

      final reports = await _apiService.getReportsWithComplexFilter(
        searchQuery: widget.searchQuery.isNotEmpty ? widget.searchQuery : null,
        categoryIds: widget.scamTypeId.isNotEmpty ? [widget.scamTypeId] : null,
        typeIds: widget.selectedType != null ? [widget.selectedType!] : null,
        severityLevels: widget.selectedSeverity != null
            ? [widget.selectedSeverity!]
            : null,
        page: _currentPage,
        limit: _pageSize,
      );

      print('Complex filter result: ${reports.length} reports');

      // Convert to UI format
      _filteredReports = reports;
      _typedReports = reports
          .map((json) => _safeConvertToReportModel(json))
          .toList();

      // Check if we have more data
      if (reports.length < _pageSize) {
        _hasMoreData = false;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complex filter: ${reports.length} reports found'),
            backgroundColor: reports.isNotEmpty ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Complex filter failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Complex filter failed: $e';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complex filter failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Enhanced method to get report display info using ReportModel
  String _getReportTypeDisplayEnhanced(ReportModel report) {
    // Use the new ReportModel helper methods
    final categoryName = report.displayCategory;
    final typeName = report.displayType;

    if (categoryName.isNotEmpty &&
        typeName.isNotEmpty &&
        categoryName != 'Unknown Category' &&
        typeName != 'Unknown Type') {
      return '$categoryName - $typeName';
    } else if (categoryName.isNotEmpty && categoryName != 'Unknown Category') {
      return categoryName;
    } else if (typeName.isNotEmpty && typeName != 'Unknown Type') {
      return typeName;
    } else {
      // Try to get from the original data if available
      if (report.categoryName != null && report.categoryName!.isNotEmpty) {
        return report.categoryName!;
      } else if (report.typeName != null && report.typeName!.isNotEmpty) {
        return report.typeName!;
      } else {
        return report.displayName;
      }
    }
  }

  // Enhanced method to check if report has evidence using ReportModel
  bool _hasEvidenceEnhanced(ReportModel report) {
    return report.email?.isNotEmpty == true ||
        report.phoneNumber?.isNotEmpty == true ||
        report.website?.isNotEmpty == true ||
        report.screenshotPaths.isNotEmpty ||
        report.documentPaths.isNotEmpty;
  }

  // Enhanced method to get report status using ReportModel
  String _getReportStatusEnhanced(ReportModel report) {
    if (report.isSynced) {
      return 'Completed';
    } else if (report.status?.toLowerCase() == 'pending') {
      return 'Pending';
    } else if (report.id != null && report.id!.startsWith('_')) {
      // If report has a backend ID, it's completed
      return 'Completed';
    } else if (report.reportCategoryId != null || report.reportTypeId != null) {
      // If report has category or type IDs, it's likely from backend
      return 'Completed';
    } else {
      return 'Pending';
    }
  }

  // Enhanced method to get time ago using ReportModel
  String _getTimeAgoEnhanced(ReportModel report) {
    final date = report.sortDate;
    if (date == null) return 'Unknown time';

    try {
      final now = DateTime.now();
      final difference = now.difference(date);

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

  // Enhanced method to get priority color using ReportModel
  Color _getPriorityColor(ReportModel report) {
    if (report.isHighPriority) {
      return Colors.red;
    } else if (report.isMediumPriority) {
      return Colors.orange;
    } else if (report.isLowPriority) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  // Enhanced method to get severity color using ReportModel
  Color _getSeverityColor(ReportModel report) {
    final severity = report.displaySeverity.toLowerCase();
    switch (severity) {
      case 'critical':
        return Colors.purple;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // New method to build enhanced report card using ReportModel
  Widget _buildEnhancedReportCard(ReportModel report, int index) {
    final reportType = _getReportTypeDisplayEnhanced(report);
    final hasEvidence = _hasEvidenceEnhanced(report);
    final status = _getReportStatusEnhanced(report);
    final timeAgo = _getTimeAgoEnhanced(report);
    final priorityColor = _getPriorityColor(report);
    final severityColor = _getSeverityColor(report);

    return GestureDetector(
      onTap: () {
        // Navigate to report detail view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailView(
              report: _filteredReports[index],
              typedReport: report,
            ),
          ),
        );
      },
      child: Container(
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
          // Report Icon with Priority Color
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),

          // Report Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report Type
                Text(
                  reportType,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  report.description ?? 'No description available',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                        color: severityColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report.displaySeverity,
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

                    // Priority Tag (if high priority)
                    if (report.isHighPriority) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'HIGH PRIORITY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Tags (if any)
                if (report.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: report.tags
                        .take(3)
                        .map(
                          (tag) => Chip(
                            label: Text(tag, style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.grey[200],
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),

              // Status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == 'Pending')
                    Icon(Icons.sync, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: status == 'Completed'
                          ? Colors.green
                          : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: const Text('Thread Database'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [],
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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreadDatabaseFilterPage(),
                      ),
                    );
                    // If we returned from filter page, reset and reload with new filters
                    if (result == true) {
                      await _resetAndReload();
                    }
                  },
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
                        SizedBox(height: 100), // Add some space at the top
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No reports found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or pull to refresh',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _resetAndReload,
                                child: Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Total reports in database: ${_filteredReports.length}',
                              ),
                              SizedBox(height: 8),
                              Text('Applied filters:'),
                              Text('- Search: "${widget.searchQuery}"'),
                              Text('- Category: "${widget.scamTypeId}"'),
                              Text('- Type: "${widget.selectedType}"'),
                              Text('- Severity: "${widget.selectedSeverity}"'),
                              SizedBox(height: 8),
                              Text('Hive Box Status:'),
                              Text(
                                '- Scam reports: ${Hive.box<ScamReportModel>('scam_reports').length}',
                              ),
                              Text(
                                '- Fraud reports: ${Hive.box<FraudReportModel>('fraud_reports').length}',
                              ),
                              Text(
                                '- Malware reports: ${Hive.box<MalwareReportModel>('malware_reports').length}',
                              ),
                              SizedBox(height: 8),
                              Text('Category & Type Cache:'),
                              Text(
                                '- Categories loaded: ${_categoryIdToName.length}',
                              ),
                              Text('- Types loaded: ${_typeIdToName.length}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _resetAndReload,
                    child: ListView.builder(
                      controller: _scrollController,
                      // Add scroll controller
                      itemCount:
                          _filteredReports.length + (_hasMoreData ? 1 : 0),
                      // Add 1 for loading indicator
                      itemBuilder: (context, index) {
                        // Show loading indicator or end message at the bottom
                        if (index == _filteredReports.length) {
                          if (_isLoadingMore) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 8),
                                    Text('Loading more reports...'),
                                  ],
                                ),
                              ),
                            );
                          } else if (!_hasMoreData &&
                              _filteredReports.isNotEmpty) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'All reports loaded',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Total: ${_filteredReports.length} reports',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        }
                        // Use enhanced report card if we have typed reports
                        if (_typedReports.isNotEmpty &&
                            index < _typedReports.length) {
                          return _buildEnhancedReportCard(
                            _typedReports[index],
                            index,
                          );
                        }

                        // Fallback to original report card
                        final report = _filteredReports[index];
                        final reportType = _getReportTypeDisplay(report);
                        final hasEvidence = _hasEvidence(report);
                        final status = _getReportStatus(report);
                        final timeAgo = _getTimeAgo(report['createdAt']);

                        // Enhanced category and type name resolution
                        String categoryName = '';
                        String typeName = '';

                        // Check if this is a malware report
                        final reportTypeValue =
                            report['type']?.toString() ?? '';
                        final isMalwareReport = reportTypeValue == 'Malware';

                        if (isMalwareReport) {
                          // For malware reports, use malwareType as the type
                          categoryName =
                              'Malware'; // Set a default category for malware
                          typeName =
                              report['malwareType']?.toString() ??
                              'Unknown Malware Type';
                        } else {
                          // For scam and fraud reports, use the existing logic
                          // Try to get category name from different possible sources
                          final categoryObj = report['reportCategoryId'];
                          if (categoryObj is Map) {
                            categoryName =
                                categoryObj['name']?.toString() ??
                                categoryObj['categoryName']?.toString() ??
                                categoryObj['title']?.toString() ??
                                '';
                          } else if (categoryObj is String) {
                            // If it's a string ID, try to resolve it from cache
                            categoryName =
                                _resolveCategoryName(categoryObj) ?? '';
                          }

                          // Try to get type name from different possible sources
                          final typeObj = report['reportTypeId'];
                          if (typeObj is Map) {
                            typeName =
                                typeObj['name']?.toString() ??
                                typeObj['typeName']?.toString() ??
                                typeObj['title']?.toString() ??
                                '';
                          } else if (typeObj is String) {
                            // If it's a string ID, try to resolve it from cache
                            typeName = _resolveTypeName(typeObj) ?? '';
                          }

                          // Fallback: if we still don't have names, try to get them from other fields
                          if (categoryName.isEmpty) {
                            categoryName =
                                report['categoryName']?.toString() ??
                                report['category']?.toString() ??
                                report['reportCategory']?.toString() ??
                                '';
                          }

                          if (typeName.isEmpty) {
                            typeName =
                                report['typeName']?.toString() ??
                                report['type']?.toString() ??
                                report['reportType']?.toString() ??
                                '';
                          }

                          // Fallback: if we still don't have names, show the IDs
                          if (categoryName.isEmpty) {
                            final categoryId =
                                report['reportCategoryId']?.toString() ?? '';
                            if (categoryId.isNotEmpty) {
                              categoryName = 'Category ID: $categoryId';
                            }
                          }

                          if (typeName.isEmpty) {
                            final typeId =
                                report['reportTypeId']?.toString() ?? '';
                            if (typeId.isNotEmpty) {
                              typeName = 'Type ID: $typeId';
                            }
                          }
                        }

                        // Debug: Print the extracted names
                        print(
                          'Report ${report['_id'] ?? report['id']}: Category="$categoryName", Type="$typeName" (Type: $reportTypeValue)',
                        );

                        return GestureDetector(
                          onTap: () {
                            // Navigate to report detail view
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDetailView(
                                  report: report,
                                  typedReport: null,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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
                                    // Report Category and Type
                                    if (categoryName.isNotEmpty)
                                      Text(
                                        'Category: $categoryName',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    if (categoryName.isNotEmpty &&
                                        typeName.isNotEmpty)
                                      const SizedBox(height: 4),
                                    if (typeName.isNotEmpty)
                                      Text(
                                        'Type: $typeName',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (categoryName.isNotEmpty ||
                                        typeName.isNotEmpty)
                                      const SizedBox(height: 8),
                                    // Description
                                    Text(
                                      report['description'] ??
                                          'No description available',
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
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: severityColor(
                                              report['alertLevels'] ?? '',
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: hasEvidence
                                                ? Colors.blue
                                                : Colors.grey[600],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            hasEvidence
                                                ? 'Has Evidence'
                                                : 'No Evidence',
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
                                          color: status == 'Completed'
                                              ? Colors.green
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
