import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../dashboard_page.dart';
import 'theard_database.dart';
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
  final List<String> selectedTypes;
  final List<String> selectedSeverities;
  final List<String> selectedCategories;
  final bool hasSearchQuery;
  final bool hasSelectedType;
  final bool hasSelectedSeverity;
  final bool hasSelectedCategory;
  final bool isOffline;
  final List<Map<String, dynamic>> localReports;
  final List<Map<String, dynamic>> severityLevels;

  const ThreadDatabaseListPage({
    Key? key,
    required this.searchQuery,
    this.selectedTypes = const [],
    this.selectedSeverities = const [],
    this.selectedCategories = const [],
    this.hasSearchQuery = false,
    this.hasSelectedType = false,
    this.hasSelectedSeverity = false,
    this.hasSelectedCategory = false,
    this.isOffline = false,
    this.localReports = const [],
    this.severityLevels = const [],
  }) : super(key: key);

  @override
  State<ThreadDatabaseListPage> createState() => _ThreadDatabaseListPageState();
}

class _ThreadDatabaseListPageState extends State<ThreadDatabaseListPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _filteredReports = [];
  List<ReportModel> _typedReports = [];
  Set<int> syncingIndexes = {};

  Map<String, String> _typeIdToName = {};
  Map<String, String> _categoryIdToName = {};

  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Load category and type names first
    await _loadCategoryAndTypeNames();
    // Then load reports
    await _loadFilteredReports();
  }

  Widget _buildReportCard(Map<String, dynamic> report, int index) {
    final reportType = _getReportTypeDisplay(report);
    final hasEvidence = _hasEvidence(report);
    final status = _getReportStatus(report);
    final timeAgo = _getTimeAgo(report['createdAt']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReportDetailView(report: report, typedReport: null),
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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reportType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report['description'] ?? 'No description available',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor(_getAlertLevel(report)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getAlertLevelDisplay(report),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _handleError(
        'No internet connection. Cannot load more data.',
        isWarning: true,
      );
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      List<Map<String, dynamic>> newReports = [];

      bool hasFilters =
          widget.hasSearchQuery ||
          widget.hasSelectedCategory ||
          widget.hasSelectedType ||
          widget.hasSelectedSeverity;

      if (hasFilters) {
        print('🔍 ThreadDB Debug - hasFilters: $hasFilters');
        print('🔍 ThreadDB Debug - widget.hasSelectedSeverity: ${widget.hasSelectedSeverity}');
        print('🔍 ThreadDB Debug - widget.selectedSeverities: ${widget.selectedSeverities}');
        print('🔍 ThreadDB Debug - widget.selectedSeverities isEmpty: ${widget.selectedSeverities.isEmpty}');
        
        // Convert alert level IDs to names for API
        final severityLevelsForAPI = widget.hasSelectedSeverity && widget.selectedSeverities.isNotEmpty
            ? widget.selectedSeverities.map((severityId) {
                // Find the alert level name from the severityLevels list
                final alertLevel = widget.severityLevels.firstWhere(
                  (level) => (level['_id'] ?? level['id']) == severityId,
                  orElse: () => {'name': severityId.toLowerCase()},
                );
                return (alertLevel['name'] ?? severityId).toString().toLowerCase();
              }).toList()
            : null;
        
        print('🔍 ThreadDB Debug - severityLevelsForAPI: $severityLevelsForAPI');
        
        newReports = await _apiService.getReportsWithComplexFilter(
          searchQuery: widget.hasSearchQuery ? widget.searchQuery : null,
          categoryIds:
              widget.hasSelectedCategory && widget.selectedCategories.isNotEmpty
              ? widget.selectedCategories
              : null,
          typeIds: widget.hasSelectedType && widget.selectedTypes.isNotEmpty
              ? widget.selectedTypes
              : null,
          severityLevels: severityLevelsForAPI,
          page: _currentPage,
          limit: _pageSize,
        );
      } else {
        final filter = ReportsFilter(page: _currentPage, limit: _pageSize);
        newReports = await _apiService.fetchReportsWithFilter(filter);
      }

      if (newReports.isNotEmpty) {
        final existingIds = _filteredReports
            .map((r) => r['_id'] ?? r['id'])
            .toSet();
        final uniqueNewReports = newReports.where((report) {
          final reportId = report['_id'] ?? report['id'];
          return reportId != null && !existingIds.contains(reportId);
        }).toList();

        if (uniqueNewReports.isNotEmpty) {
          _filteredReports.addAll(uniqueNewReports);
          _typedReports.addAll(
            uniqueNewReports.map((json) => _safeConvertToReportModel(json)),
          );

          if (newReports.length < _pageSize) {
            _hasMoreData = false;
          }
        } else if (newReports.length < _pageSize) {
          _hasMoreData = false;
        }
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      _currentPage--;
      _handleError('Failed to load more data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

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

  ReportModel _safeConvertToReportModel(Map<String, dynamic> json) {
    try {
      final normalizedJson = _normalizeReportData(json);
      return ReportModel.fromJson(normalizedJson);
    } catch (e) {
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

  Map<String, dynamic> _normalizeReportData(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    if (normalized['reportCategoryId'] is Map) {
      final categoryMap = normalized['reportCategoryId'] as Map;
      normalized['reportCategoryId'] =
          categoryMap['_id'] ?? categoryMap['id'] ?? '';
      if (categoryMap['name'] != null) {
        normalized['categoryName'] = categoryMap['name'].toString();
      }
    }

    if (normalized['reportTypeId'] is Map) {
      final typeMap = normalized['reportTypeId'] as Map;
      normalized['reportTypeId'] = typeMap['_id'] ?? typeMap['id'] ?? '';
      if (typeMap['name'] != null) {
        normalized['typeName'] = typeMap['name'].toString();
      }
    }

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

    if (normalized['_id'] != null) {
      normalized['isSynced'] = true;
    }

    return normalized;
  }

  Future<void> _resetAndReload() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
      _filteredReports.clear();
      _typedReports.clear();
    });
    await _loadFilteredReports();
  }

  Future<void> _loadFilteredReports() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _currentPage = 1;
          _hasMoreData = true;
        });
      }

      List<Map<String, dynamic>> reports = [];

      // Check if we're in offline mode or have local reports
      if (widget.isOffline || widget.localReports.isNotEmpty) {
        print('📱 Using offline/local data');
        reports = widget.localReports.isNotEmpty 
            ? widget.localReports 
            : await _getLocalReports();
      } else {
        // Online mode - try API first
        bool hasFilters =
            widget.hasSearchQuery ||
            widget.hasSelectedCategory ||
            widget.hasSelectedType ||
            widget.hasSelectedSeverity;

        try {
          if (hasFilters) {
            print('🔍 ThreadDB Debug - hasFilters: $hasFilters');
            print('🔍 ThreadDB Debug - searchQuery: ${widget.searchQuery}');
            print('🔍 ThreadDB Debug - selectedCategories: ${widget.selectedCategories}');
            print('🔍 ThreadDB Debug - selectedTypes: ${widget.selectedTypes}');
            print('🔍 ThreadDB Debug - selectedSeverities: ${widget.selectedSeverities}');
            print('🔍 ThreadDB Debug - hasSelectedCategory: ${widget.hasSelectedCategory}');
            print('🔍 ThreadDB Debug - hasSelectedType: ${widget.hasSelectedType}');
            print('🔍 ThreadDB Debug - hasSelectedSeverity: ${widget.hasSelectedSeverity}');
            
            final categoryIdsForAPI = widget.hasSelectedCategory &&
                widget.selectedCategories.isNotEmpty
                ? widget.selectedCategories
                : null;
            final typeIdsForAPI = widget.hasSelectedType && widget.selectedTypes.isNotEmpty
                ? widget.selectedTypes
                : null;
            final severityLevelsForAPI = widget.hasSelectedSeverity &&
                widget.selectedSeverities.isNotEmpty
                ? widget.selectedSeverities.map((severityId) {
                    // Find the alert level name from the severityLevels list
                    final alertLevel = widget.severityLevels.firstWhere(
                      (level) => (level['_id'] ?? level['id']) == severityId,
                      orElse: () => {'name': severityId.toLowerCase()},
                    );
                    return (alertLevel['name'] ?? severityId).toString().toLowerCase();
                  }).toList()
                : null;
            
            print('🔍 ThreadDB Debug - categoryIdsForAPI: $categoryIdsForAPI');
            print('🔍 ThreadDB Debug - typeIdsForAPI: $typeIdsForAPI');
            print('🔍 ThreadDB Debug - severityLevelsForAPI: $severityLevelsForAPI');
            
            reports = await _apiService.getReportsWithComplexFilter(
              searchQuery: widget.hasSearchQuery ? widget.searchQuery : null,
              categoryIds: categoryIdsForAPI,
              typeIds: typeIdsForAPI,
              severityLevels: severityLevelsForAPI,
              page: _currentPage,
              limit: _pageSize,
            );
            print('🔍 ThreadDB Debug - API returned ${reports.length} reports');
          } else {
            final filter = ReportsFilter(page: _currentPage, limit: _pageSize);
            reports = await _apiService.fetchReportsWithFilter(filter);
            print('🔍 ThreadDB Debug - Simple filter returned ${reports.length} reports');
          }
        } catch (e) {
          print('❌ API failed, falling back to local data: $e');
          // Fallback to local data
          reports = await _getLocalReports();
        }
      }

      // Apply filters to the reports
      _filteredReports = _applyFilters(reports);
      _typedReports = _filteredReports
          .map((json) => _safeConvertToReportModel(json))
          .toList();

      if (reports.length < _pageSize) {
        _hasMoreData = false;
      }

      if (mounted) {
        setState(() => _isLoading = false);
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

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> reports) {
    List<Map<String, dynamic>> filtered = reports;

    if (widget.hasSearchQuery && widget.searchQuery.isNotEmpty) {
      final searchTerm = widget.searchQuery.toLowerCase();
      filtered = filtered.where((report) {
        final description =
            report['description']?.toString().toLowerCase() ?? '';
        final email = report['email']?.toString().toLowerCase() ?? '';
        final phone = report['phoneNumber']?.toString().toLowerCase() ?? '';
        final website = report['website']?.toString().toLowerCase() ?? '';
        return description.contains(searchTerm) ||
            email.contains(searchTerm) ||
            phone.contains(searchTerm) ||
            website.contains(searchTerm);
      }).toList();
    }

    if (widget.hasSelectedCategory && widget.selectedCategories.isNotEmpty) {
      filtered = filtered.where((report) {
        final cat = report['reportCategoryId'];
        String? catId = cat is Map
            ? cat['_id']?.toString() ?? cat['id']?.toString()
            : cat?.toString();
        return catId != null && widget.selectedCategories.contains(catId);
      }).toList();
    }

    if (widget.hasSelectedType && widget.selectedTypes.isNotEmpty) {
      filtered = filtered.where((report) {
        final type = report['reportTypeId'];
        String? typeId = type is Map
            ? type['_id']?.toString() ?? type['id']?.toString()
            : type?.toString();
        return typeId != null && widget.selectedTypes.contains(typeId);
      }).toList();
    }

    if (widget.hasSelectedSeverity && widget.selectedSeverities.isNotEmpty) {
      filtered = filtered.where((report) {
        final reportSeverity = _getNormalizedAlertLevel(report);

        // Check if any of the selected severities match
        return widget.selectedSeverities.any((selectedSeverityId) {
          // Convert selected severity ID to name for comparison
          final selectedSeverityName = widget.severityLevels
              .firstWhere(
                (level) => (level['_id'] ?? level['id']) == selectedSeverityId,
                orElse: () => {'name': selectedSeverityId.toLowerCase()},
              )['name']
              ?.toString()
              .toLowerCase() ?? selectedSeverityId.toLowerCase();

          // Debug print to help identify issues
          if (reportSeverity.isNotEmpty) {
            print(
              'Filtering severity: Report="$reportSeverity" vs Selected ID="$selectedSeverityId" -> Name="$selectedSeverityName"',
            );
            print('Report data: ${report['alertLevels']}');
          }

          return reportSeverity == selectedSeverityName;
        });
      }).toList();
    }

    return filtered;
  }

  Future<List<Map<String, dynamic>>> _getLocalReports() async {
    List<Map<String, dynamic>> allReports = [];

    // Get scam reports
    final scamBox = Hive.box<ScamReportModel>('scam_reports');
    for (var report in scamBox.values) {
      final categoryName = _resolveCategoryName(report.reportCategoryId ?? 'scam_category') ?? 'Report Scam';
      final typeName = _resolveTypeName(report.reportTypeId ?? 'scam_type') ?? 'Scam Report';
      
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
        'categoryName': categoryName,
        'typeName': typeName,
        'type': 'scam',
        'isSynced': report.isSynced,
      });
    }

    // Get fraud reports
    final fraudBox = Hive.box<FraudReportModel>('fraud_reports');
    for (var report in fraudBox.values) {
      final categoryName = _resolveCategoryName(report.reportCategoryId ?? 'fraud_category') ?? 'Report Fraud';
      final typeName = _resolveTypeName(report.reportTypeId ?? 'fraud_type') ?? 'Fraud Report';
      
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
        'categoryName': categoryName,
        'typeName': typeName,
        'name': report.name,
        'type': 'fraud',
        'isSynced': report.isSynced,
      });
    }

    // Get malware reports
    final malwareBox = Hive.box<MalwareReportModel>('malware_reports');
    for (var report in malwareBox.values) {
      final categoryName = _resolveCategoryName('malware_category') ?? 'Report Malware';
      final typeName = _resolveTypeName('malware_type') ?? 'Malware Report';
      
      allReports.add({
        'id': report.id,
        'description': report.malwareType ?? 'Malware Report',
        'alertLevels': report.alertSeverityLevel,
        'email': null,
        'phoneNumber': null,
        'website': null,
        'createdAt': report.date,
        'updatedAt': report.date,
        'reportCategoryId': 'malware_category',
        'reportTypeId': 'malware_type',
        'categoryName': categoryName,
        'typeName': typeName,
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

  Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getReportTypeDisplay(Map<String, dynamic> report) {
    // Debug logging
    print('🔍 Getting report type display for report: ${report['id']}');
    print('🔍 Report type: ${report['type']}');
    print('🔍 Category ID: ${report['reportCategoryId']}');
    print('🔍 Type ID: ${report['reportTypeId']}');

    // First, try to get names directly from the report
    final categoryName = report['categoryName']?.toString();
    final typeName = report['typeName']?.toString();

    if (categoryName?.isNotEmpty == true && typeName?.isNotEmpty == true) {
      print('✅ Using direct names: $categoryName - $typeName');
      return '$categoryName - $typeName';
    } else if (categoryName?.isNotEmpty == true) {
      print('✅ Using direct category name: $categoryName');
      return categoryName!;
    } else if (typeName?.isNotEmpty == true) {
      print('✅ Using direct type name: $typeName');
      return typeName!;
    }

    // Try other possible name fields
    final reportType = report['reportType']?.toString();
    final category = report['reportCategory']?.toString();

    if (reportType?.isNotEmpty == true) {
      print('✅ Using reportType: $reportType');
      return reportType!;
    }
    if (category?.isNotEmpty == true) {
      print('✅ Using category: $category');
      return category!;
    }

    // Try to resolve from IDs
    String? categoryId = _extractId(report['reportCategoryId']);
    String? typeId = _extractId(report['reportTypeId']);

    print('🔍 Extracted category ID: $categoryId');
    print('🔍 Extracted type ID: $typeId');

    String? resolvedCategoryName = categoryId?.isNotEmpty == true
        ? _resolveCategoryName(categoryId!)
        : null;
    String? resolvedTypeName = typeId?.isNotEmpty == true
        ? _resolveTypeName(typeId!)
        : null;

    print('🔍 Resolved category name: $resolvedCategoryName');
    print('🔍 Resolved type name: $resolvedTypeName');

    if (resolvedCategoryName?.isNotEmpty == true &&
        resolvedTypeName?.isNotEmpty == true) {
      print('✅ Using resolved names: $resolvedCategoryName - $resolvedTypeName');
      return '$resolvedCategoryName - $resolvedTypeName';
    } else if (resolvedCategoryName?.isNotEmpty == true) {
      print('✅ Using resolved category name: $resolvedCategoryName');
      return resolvedCategoryName!;
    } else if (resolvedTypeName?.isNotEmpty == true) {
      print('✅ Using resolved type name: $resolvedTypeName');
      return resolvedTypeName!;
    }

    // Fallback to report type
    final type = report['type']?.toString().toLowerCase();
    print('🔍 Using fallback type: $type');

    switch (type) {
      case 'scam':
        return 'Report Scam';
      case 'fraud':
        return 'Report Fraud';
      case 'malware':
        return 'Report Malware';
      default:
        if (type?.isNotEmpty == true) {
          return 'Report ${type!.substring(0, 1).toUpperCase()}${type.substring(1)}';
        } else {
          return 'Security Report';
        }
    }
  }

  String? _extractId(dynamic obj) {
    if (obj is Map) {
      return obj['_id']?.toString() ?? obj['id']?.toString();
    }
    return obj?.toString();
  }

  Future<void> _loadCategoryAndTypeNames() async {
    await Future.wait([_loadTypeNames(), _loadCategoryNames()]);
  }

  Future<void> _loadTypeNames() async {
    try {
      List<Map<String, dynamic>> types = [];
      
      // Try to load from API first
      try {
        types = await _apiService.fetchReportTypes();
        print('✅ Loaded ${types.length} types from API');
      } catch (e) {
        print('❌ Failed to load types from API: $e');
        // Try to load from local storage
        try {
          final prefs = await SharedPreferences.getInstance();
          final typesJson = prefs.getString('local_types');
          if (typesJson != null) {
            types = List<Map<String, dynamic>>.from(
              jsonDecode(typesJson).map((x) => Map<String, dynamic>.from(x))
            );
            print('✅ Loaded ${types.length} types from local storage');
          }
        } catch (e) {
          print('❌ Failed to load types from local storage: $e');
        }
      }

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
          print('📝 Type mapping: $id -> $name');
        }
      }

      // Add fallback types for common report types
      _typeIdToName['scam_type'] = 'Scam Report';
      _typeIdToName['fraud_type'] = 'Fraud Report';
      _typeIdToName['malware_type'] = 'Malware Report';
      
    } catch (e) {
      print('Error loading type names: $e');
      // Add basic fallback types
      _typeIdToName['scam_type'] = 'Scam Report';
      _typeIdToName['fraud_type'] = 'Fraud Report';
      _typeIdToName['malware_type'] = 'Malware Report';
    }
  }

  Future<void> _loadCategoryNames() async {
    try {
      List<Map<String, dynamic>> categories = [];
      
      // Try to load from API first
      try {
        categories = await _apiService.fetchReportCategories();
        print('✅ Loaded ${categories.length} categories from API');
      } catch (e) {
        print('❌ Failed to load categories from API: $e');
        // Try to load from local storage
        try {
          final prefs = await SharedPreferences.getInstance();
          final categoriesJson = prefs.getString('local_categories');
          if (categoriesJson != null) {
            categories = List<Map<String, dynamic>>.from(
              jsonDecode(categoriesJson).map((x) => Map<String, dynamic>.from(x))
            );
            print('✅ Loaded ${categories.length} categories from local storage');
          }
        } catch (e) {
          print('❌ Failed to load categories from local storage: $e');
        }
      }

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
          print('📝 Category mapping: $id -> $name');
        }
      }

      // Add fallback categories for common report types
      _categoryIdToName['scam_category'] = 'Report Scam';
      _categoryIdToName['fraud_category'] = 'Report Fraud';
      _categoryIdToName['malware_category'] = 'Report Malware';
      
    } catch (e) {
      print('Error loading category names: $e');
      // Add basic fallback categories
      _categoryIdToName['scam_category'] = 'Report Scam';
      _categoryIdToName['fraud_category'] = 'Report Fraud';
      _categoryIdToName['malware_category'] = 'Report Malware';
    }
  }

  String? _resolveTypeName(String typeId) => _typeIdToName[typeId];
  String? _resolveCategoryName(String categoryId) =>
      _categoryIdToName[categoryId];

  bool _hasEvidence(Map<String, dynamic> report) {
    final type = report['type'];
    if (type == 'malware') {
      return (report['fileName']?.toString().isNotEmpty == true) ||
          (report['malwareType']?.toString().isNotEmpty == true);
    } else {
      return (report['email']?.toString().isNotEmpty == true) ||
          (report['phoneNumber']?.toString().isNotEmpty == true) ||
          (report['website']?.toString().isNotEmpty == true);
    }
  }

  String _getReportStatus(Map<String, dynamic> report) {
    final status = report['status']?.toString().toLowerCase();
    if (status?.isNotEmpty == true) {
      if (status == 'completed' || status == 'synced' || status == 'uploaded') {
        return 'Completed';
      } else if (status == 'pending' || status == 'processing') {
        return 'Pending';
      }
    }

    if (report['isSynced'] == true ||
        report['synced'] == true ||
        report['uploaded'] == true ||
        report['completed'] == true) {
      return 'Completed';
    }

    if (report['_id'] != null ||
        (report['reportCategoryId'] != null ||
            report['reportTypeId'] != null ||
            report['malwareType'] != null)) {
      return 'Completed';
    }

    return 'Pending';
  }

  String _getAlertLevel(Map<String, dynamic> report) {
    final alertLevel =
        report['alertLevels']?.toString() ??
        report['alertSeverityLevel']?.toString() ??
        report['severity']?.toString() ??
        'Unknown';

    print('🔍 ThreadDB - Extracting alert level from report:');
    print('🔍 ThreadDB - alertLevels field: ${report['alertLevels']}');
    print(
      '🔍 ThreadDB - alertSeverityLevel field: ${report['alertSeverityLevel']}',
    );
    print('🔍 ThreadDB - severity field: ${report['severity']}');
    print('🔍 ThreadDB - Final alert level: $alertLevel');
    print('🔍 ThreadDB - Report type: ${report['type']}');
    print('🔍 ThreadDB - Report ID: ${report['id']}');

    // Normalize the alert level to lowercase for backend consistency
    final normalized = alertLevel.toLowerCase().trim();
    switch (normalized) {
      case 'low':
      case 'low risk':
      case 'low severity':
        return 'low';
      case 'medium':
      case 'medium risk':
      case 'medium severity':
        return 'medium';
      case 'high':
      case 'high risk':
      case 'high severity':
        return 'high';
      case 'critical':
      case 'critical risk':
      case 'critical severity':
        return 'critical';
      default:
        return alertLevel.isNotEmpty ? alertLevel.toLowerCase() : 'unknown';
    }
  }

  String _getNormalizedAlertLevel(Map<String, dynamic> report) {
    final alertLevel =
        report['alertLevels']?.toString() ??
        report['alertSeverityLevel']?.toString() ??
        report['severity']?.toString() ??
        '';

    // Normalize the alert level to lowercase for consistent comparison and backend compatibility
    final normalized = alertLevel.toLowerCase().trim();

    // Map common variations to standard lowercase format for backend
    switch (normalized) {
      case 'low':
      case 'low risk':
      case 'low severity':
        return 'low';
      case 'medium':
      case 'medium risk':
      case 'medium severity':
        return 'medium';
      case 'high':
      case 'high risk':
      case 'high severity':
        return 'high';
      case 'critical':
      case 'critical risk':
      case 'critical severity':
        return 'critical';
      default:
        return normalized;
    }
  }

  // Method to get display version of alert level (properly capitalized for UI)
  String _getAlertLevelDisplay(Map<String, dynamic> report) {
    final alertLevel = _getAlertLevel(report);
    
    // Convert lowercase backend values to proper display format
    switch (alertLevel.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return alertLevel.isNotEmpty ? alertLevel.substring(0, 1).toUpperCase() + alertLevel.substring(1).toLowerCase() : 'Unknown';
    }
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Unknown time';

    try {
      DateTime createdDate = createdAt is String
          ? DateTime.parse(createdAt)
          : createdAt is DateTime
          ? createdAt
          : throw Exception('Invalid date');
      final now = DateTime.now();
      final difference = now.difference(createdDate);

      if (difference.inMinutes < 60)
        return '${difference.inMinutes} minutes ago';
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      return '${difference.inDays} days ago';
    } catch (e) {
      return 'Unknown time';
    }
  }

  Future<void> _manualSync(int index, Map<String, dynamic> report) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No internet connection.')));
      return;
    }

    if (mounted) setState(() => syncingIndexes.add(index));

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
        if (mounted) setState(() => _filteredReports[index]['isSynced'] = true);
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
      if (mounted) setState(() => syncingIndexes.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
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
          // Offline Status Indicator
          if (widget.isOffline)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline Mode - Showing local data',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.localReports.length} reports available',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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
                              Text(
                                '- Categories: "${widget.selectedCategories.join(", ")}"',
                              ),
                              Text(
                                '- Types: "${widget.selectedTypes.join(", ")}"',
                              ),
                              Text(
                                '- Severities: "${widget.selectedSeverities.join(", ")}"',
                              ),
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
                        // Use typed reports if available
                        if (_typedReports.isNotEmpty &&
                            index < _typedReports.length) {
                          final report = _typedReports[index];
                          return _buildReportCard(
                            _filteredReports[index],
                            index,
                          );
                        }

                        return _buildReportCard(_filteredReports[index], index);

                        return _buildReportCard(_filteredReports[index], index);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
