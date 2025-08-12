import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:security_alert/screens/scam/scam_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/jwt_service.dart';
import '../../services/token_storage.dart';
import '../../models/scam_report_model.dart';
import '../../custom/customButton.dart';
import '../../custom/customDropdown.dart';
import '../../custom/Success_page.dart';
import '../../services/api_service.dart';
import '../../custom/fileUpload.dart';

class ReportScam2 extends StatefulWidget {
  final ScamReportModel report;
  const ReportScam2({required this.report});

  @override
  State<ReportScam2> createState() => _ReportScam2State();
}

class _ReportScam2State extends State<ReportScam2> {
  final _formKey = GlobalKey<FormState>();
  String? alertLevel;
  String? alertLevelId; // Add alert level ID
  final List<String> alertLevels = ['Low', 'Medium', 'High', 'Critical'];
  List<Map<String, dynamic>> alertLevelOptions =
      []; // Store alert level options from API
  bool isUploading = false;
  String uploadStatus = '';
  Map<String, dynamic>? uploadedFilesData;
  bool filesUploaded = false;
  String? selectedAddress; // Add selected address variable

  final GlobalKey<FileUploadWidgetState> _fileUploadKey =
      GlobalKey<FileUploadWidgetState>(debugLabel: 'scam_file_upload_${DateTime.now().millisecondsSinceEpoch}');

  @override
  void initState() {
    super.initState();
    alertLevel = widget.report.alertLevels;
    _loadAlertLevels();

    // Debug: Print received data
    print('🔍 Received report data in Step 2:');
    print('🔍 - Phone Numbers: ${widget.report.phoneNumbers}');
    print('🔍 - Email Addresses: ${widget.report.emailAddresses}');
    print('🔍 - Social Media Handles: ${widget.report.socialMediaHandles}');
    print('🔍 - Report ID: ${widget.report.id}');
    print('🔍 - Report JSON: ${widget.report.toJson()}');
  }

  Future<void> _loadAlertLevels() async {
    try {
      print('🔍 Loading alert levels from API...');

      // Try to fetch alert levels from backend
    try {
      final apiService = ApiService();
      final alertLevels = await apiService.fetchAlertLevels();
      
      if (alertLevels.isNotEmpty) {
          if (mounted) {
        setState(() {
          alertLevelOptions = alertLevels;
        });
        print('🔍 Loaded ${alertLevels.length} alert levels from API');
            print(
              '🔍 Alert levels: ${alertLevels.map((level) => '${level['name']} (${level['_id']})').join(', ')}',
            );
          }
        } else {
          throw Exception('No alert levels returned from API');
        }
      } catch (e) {
        print('❌ Error loading alert levels from API: $e');
        print('🔍 Showing error message to user...');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load alert levels from server. Please check your connection and try again.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading alert levels: $e');
    }
  }

  // Debug method to test backend connectivity
  Future<void> _testBackendConnectivity() async {
    print('🧪 Testing backend connectivity...');

    try {
      // Test 1: Check if we can reach the backend
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;
      print('🌐 Network connectivity: ${isOnline ? 'Online' : 'Offline'}');

      if (!isOnline) {
        print('❌ No internet connection');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No internet connection detected'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Test 2: Check authentication token
      final token = await TokenStorage.getAccessToken();
      print(
        '🔐 Authentication token: ${token != null && token.isNotEmpty ? 'Present' : 'Not present'}',
      );

      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication token not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Test 3: Try a simple API call
      try {
        final response = await ApiService().fetchAllReports();
        print(
          '✅ Backend API test successful: ${response.length} reports found',
        );
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(
        //       'Backend connection successful! Found ${response.length} reports',
        //     ),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      } catch (e) {
        print('❌ Backend API test failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backend connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Backend connectivity test failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connectivity test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitFinalReport() async {
    print('🚀 Starting scam report submission...');
    print('🚀 Alert level: $alertLevel');
    print('🚀 Report ID: ${widget.report.id}');
    print('🚀 Report type: ${widget.report.reportTypeId}');

    if (alertLevel == null || alertLevel!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an alert severity level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

          setState(() {
        isUploading = true;
        uploadStatus = 'Preparing report submission with auto-uploaded files...';
      });

    try {
      // Test backend connectivity first
      await _testBackendConnectivity();

      // Use already uploaded files from FileUploadWidget (auto-upload enabled)
      Map<String, dynamic> uploadedFiles = {
        'screenshots': [],
        'documents': [],
        'voiceMessages': [],
        'videofiles': [],
      };

      // Get uploaded files from FileUploadWidget state (auto-upload enabled)
      if (_fileUploadKey.currentState != null) {
        final state = _fileUploadKey.currentState!;
        print('🚀 File upload state found');
        
        // Get the already uploaded files from the widget
        uploadedFiles = state.getCurrentUploadedFiles();
        
        print('🚀 Using already uploaded files from auto-upload');
        print('🚀 Uploaded files: $uploadedFiles');
        print('🚀 Screenshots: ${uploadedFiles['screenshots']?.length ?? 0}');
        print('🚀 Documents: ${uploadedFiles['documents']?.length ?? 0}');
        print('🚀 Voice messages: ${uploadedFiles['voiceMessages']?.length ?? 0}');
        print('🚀 Video files: ${uploadedFiles['videofiles']?.length ?? 0}');
      } else {
        print('🚀 File upload state not found');
      }

      // Use categorized file objects for backend and URLs for local storage
      final screenshotsForBackend = (uploadedFiles['screenshots'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();

      final documentsForBackend = (uploadedFiles['documents'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();

      final voiceMessagesForBackend = (uploadedFiles['voiceMessages'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();
      final videoMessagesForBackend = (uploadedFiles['videofiles'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();

      // Extract URLs for local model storage
      final screenshots = screenshotsForBackend
          .map((f) => f['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final documents = documentsForBackend
          .map((f) => f['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final voiceMessages = voiceMessagesForBackend
          .map((f) => f['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
      final videofiles = videoMessagesForBackend
          .map((f) => f['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      print('🚀 Extracted file URLs:');
      print('🚀 - Screenshots: ${screenshots.length}');
      print('🚀 - Documents: ${documents.length}');
      print('🚀 - Voice messages: ${voiceMessages.length}');


      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;
      print('🚀 Connectivity status: ${isOnline ? 'Online' : 'Offline'}');

      // Validate alert level ID before submission
      if (alertLevelId == null || alertLevelId!.isEmpty) {
        print('❌ Alert level ID is null or empty');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select an alert severity level'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isUploading = false;
        });
        return;
      }

      print('✅ Alert level ID validated: $alertLevelId');

      // Prepare form data for backend submission - EXACT FORMAT MATCH
      final formData = {
        // Required fields with exact backend format
        'reportCategoryId': widget.report.reportCategoryId,
        'reportTypeId': widget.report.reportTypeId,
        'alertLevels':
            alertLevelId, // This should be the alert level ID, not name
        'keycloackUserId':
            await JwtService.getCurrentUserId() ??
            widget.report.keycloakUserId ??
            '',
        'createdBy':
            await JwtService.getCurrentUserEmail() ??
            await JwtService.getCurrentUserId() ??
            widget.report.keycloakUserId ??
            '',
        'isActive': true,
        'location': await _getCurrentLocation(), // Dynamic coordinates
        'phoneNumbers': widget.report.phoneNumbers ?? [],
        'emails': widget.report.emailAddresses ?? [],
        'mediaHandles': widget.report.socialMediaHandles ?? [],
        'methodOfContact': widget.report.methodOfContactId ?? '',
        'website': widget.report.website ?? '',
        'currency': widget.report.currency ?? 'INR',
        'moneyLost': widget.report.amountLost?.toString() ?? '0',
        'reportOutcome': false,
        'description': widget.report.description ?? '',
        'incidentDate':
            widget.report.incidentDateTime?.toUtc().toIso8601String() ??
            DateTime.now().toUtc().toIso8601String(),
        'scammerName': widget.report.scammerName ?? '',
        'screenshots': screenshotsForBackend,
        'voiceMessages': voiceMessagesForBackend,
        'documents': documentsForBackend,
        'videofiles':videoMessagesForBackend,
        'createdAt':
            widget.report.createdAt?.toUtc().toIso8601String() ??
            DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      print('🚀 Form data prepared for backend submission');
      print('🚀 Form data keys: ${formData.keys.toList()}');
      print('🚀 Report Category ID: ${formData['reportCategoryId']}');
      print('🚀 Report Type ID: ${formData['reportTypeId']}');
      print('🚀 Alert Levels: ${formData['alertLevels']}');
      print('🚀 Keycloak User ID: ${formData['keycloackUserId']}');
      print('🚀 Created By: ${formData['createdBy']}');
      print(
        '🚀 Phone Numbers: ${formData['phoneNumbers']} (type: ${formData['phoneNumbers'].runtimeType})',
      );
      print(
        '🚀 Emails: ${formData['emails']} (type: ${formData['emails'].runtimeType})',
      );
      print(
        '🚀 Media Handles: ${formData['mediaHandles']} (type: ${formData['mediaHandles'].runtimeType})',
      );
      print('🚀 Phone Numbers from widget: ${widget.report.phoneNumbers}');
      print('🚀 Emails from widget: ${widget.report.emailAddresses}');
      print(
        '🚀 Media Handles from widget: ${widget.report.socialMediaHandles}',
      );

      // Validate arrays are not empty
      if (widget.report.phoneNumbers?.isEmpty ?? true) {
        print('⚠️ Warning: Phone numbers array is empty');
      }
      if (widget.report.emailAddresses?.isEmpty ?? true) {
        print('⚠️ Warning: Email addresses array is empty');
      }
      if (widget.report.socialMediaHandles?.isEmpty ?? true) {
        print('⚠️ Warning: Social media handles array is empty');
      }
      print('🚀 Screenshots: ${formData['screenshots']}');
      print('🚀 Voice Messages: ${formData['voiceMessages']}');
      print('🚀 Documents: ${formData['documents']}');

      // Create updated report model with all data including uploaded files
      final updatedReport = widget.report.copyWith(
        alertLevels: alertLevel,
        screenshotPaths: screenshots,
        documentPaths: documents,
        voiceRecordings: voiceMessages,
        updatedAt: DateTime.now(),
        isSynced: isOnline, // Mark as synced if online
      );

      print('🚀 Updated report model created');

      // Save to local thread database first (offline-first approach)
      setState(() {
        uploadStatus = 'Saving to local database...';
      });

      print('💾 Starting local database save...');
      final box = Hive.box<ScamReportModel>('scam_reports');
      print('💾 Box length before save: ${box.length}');
      print('💾 Report to save: ${updatedReport.toJson()}');

      if (updatedReport.isInBox) {
        await ScamReportService.updateReport(updatedReport);
        print('✅ Updated existing report in local database');
      } else {
        await ScamReportService.saveReportOffline(updatedReport);
        print('✅ Saved new report to local database');
      }

      print('💾 Box length after save: ${box.length}');

      // Verify the save by reading back the data
      final allReports = box.values.toList();
      print('💾 Total reports in database: ${allReports.length}');
      if (allReports.isNotEmpty) {
        final lastReport = allReports.last;
        print('💾 Last saved report: ${lastReport.toJson()}');
      }

      // Additional verification - check if we can read the data back
      print('🔍 Verifying data persistence...');
      final verificationBox = Hive.box<ScamReportModel>('scam_reports');
      final allStoredReports = verificationBox.values.toList();
      print('🔍 Total reports after save: ${allStoredReports.length}');

      if (allStoredReports.isNotEmpty) {
        final latestReport = allStoredReports.last;
        print('🔍 Latest report details:');
        print('🔍 - ID: ${latestReport.id}');
        print('🔍 - Description: ${latestReport.description}');
        print('🔍 - Alert Level: ${latestReport.alertLevels}');
        print('🔍 - Created At: ${latestReport.createdAt}');
        print('🔍 - Is Synced: ${latestReport.isSynced}');
        print('🔍 - Screenshot Paths: ${latestReport.screenshotPaths}');
        print('🔍 - Document Paths: ${latestReport.documentPaths}');
      }

      // Test thread database visibility
      print('🧪 Testing thread database visibility...');
      await _testThreadDatabaseVisibility();

      // Submit to backend if online - TEMPORARILY BYPASS CONNECTIVITY TEST
      if (isOnline) {
        try {
          setState(() {
            uploadStatus = 'Submitting to backend...';
          });

          print('🌐 Starting backend submission...');
          print('🌐 Form data being sent: ${jsonEncode(formData)}');

          await ApiService().submitScamReport(formData);
          print('✅ Backend submission successful');

          // Update local report to mark as synced
          final syncedReport = updatedReport.copyWith(isSynced: true);
          if (syncedReport.isInBox) {
            await ScamReportService.updateReport(syncedReport);
          print('✅ Updated local report as synced');
          } else {
            await ScamReportService.saveReportOffline(syncedReport);
            print('✅ Saved synced report to local database');
          }

          setState(() {
            uploadStatus = 'Successfully saved to backend and local database!';
          });
        } catch (e) {
          print('❌ Error syncing with backend: $e');
          print('❌ Error stack trace: ${StackTrace.current}');
          setState(() {
            uploadStatus =
                'Saved locally, but backend sync failed. Will retry later.';
          });
        }
      } else {
        setState(() {
          uploadStatus = 'Saved to local database. Will sync when online.';
        });
        print('📱 Offline mode - report saved locally for later sync');
      }

      setState(() {
        isUploading = false;
      });

      // Show success message and navigate
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportSuccess(label: 'Scam Report'),
          ),
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline
                  ? 'Scam report successfully submitted and saved locally!'
                  : 'Scam report saved locally. Will sync when online.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      print('❌ Submission failed: $e\n$stack');
      setState(() {
        isUploading = false;
        uploadStatus = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }



  // Add method to validate form before submission
  bool _validateForm() {
    if (alertLevel == null || alertLevel!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an alert severity level'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  // Add method to get current location dynamically
  Future<Map<String, dynamic>> _getCurrentLocation() async {
    try {
      print('📍 Getting current location...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return {
          'type': 'Point',
          'coordinates': [0.0, 0.0], // Fallback coordinates
          'address': 'Location services disabled',
        };
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return {
            'type': 'Point',
            'coordinates': [0.0, 0.0], // Fallback coordinates
            'address': 'Location permission denied',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied forever');
        return {
          'type': 'Point',
          'coordinates': [0.0, 0.0], // Fallback coordinates
          'address': 'Location permission denied',
        };
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');

      // Get real address using geocoding
      String address =
          selectedAddress ?? '${position.latitude}, ${position.longitude}';

      // If no selected address, try to get real address from coordinates
      if (selectedAddress == null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks[0];
            address = [
              placemark.street,
              placemark.subLocality,
              placemark.locality,
              placemark.administrativeArea,
              placemark.country,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          }
        } catch (e) {
          print('❌ Error getting address from coordinates: $e');
          // Keep the coordinates as fallback
          address = '${position.latitude}, ${position.longitude}';
        }
      }

      return {
        'type': 'Point',
        'coordinates': [
          position.longitude,
          position.latitude,
        ], // [lng, lat] format
        'address': address,
      };
    } catch (e) {
      print('❌ Error getting location: $e');
      return {
        'type': 'Point',
        'coordinates': [0.0, 0.0], // Fallback coordinates
        'address': 'Location error',
      };
    }
  }

  // Add a test method to verify thread database visibility
  Future<void> _testThreadDatabaseVisibility() async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    final allReports = box.values.toList();
    print('🧪 Thread Database Visibility Test:');
    print('🧪 - Total reports in thread box: ${allReports.length}');
    if (allReports.isNotEmpty) {
      final latestReport = allReports.last;
      print('🧪 - Latest report in thread box:');
      print('🧪   - ID: ${latestReport.id}');
      print('🧪   - Description: ${latestReport.description}');
      print('🧪   - Alert Level: ${latestReport.alertLevels}');
      print('🧪   - Created At: ${latestReport.createdAt}');
      print('🧪   - Is Synced: ${latestReport.isSynced}');
      print('🧪   - Screenshot Paths: ${latestReport.screenshotPaths}');
      print('🧪   - Document Paths: ${latestReport.documentPaths}');
      } else {
      print('🧪 - No reports found in thread box.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Evidence')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              FileUploadWidget(
                key: _fileUploadKey,
                config: FileUploadConfig(
                  reportType: 'scam',
                  reportId: widget.report.id ?? FileUploadService.generateObjectId(),
                  autoUpload: true, // Enable auto-upload
                  showProgress: true,
                  allowMultipleFiles: true,
                ),
                onFilesUploaded: (files) {
                  setState(() {
                    uploadedFilesData = files;
                    filesUploaded = true;
                  });
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(
                  //     content: Text('Files uploaded successfully!'),
                  //     backgroundColor: Colors.green,
                  //   ),
                  // );
                },
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File upload error: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                label: 'Alert Severity *',
                hint: 'Select severity (Required)',
                items: alertLevelOptions.isNotEmpty
                    ? alertLevelOptions
                          .map((level) => level['name'] as String)
                          .toList()
                    : alertLevels,
                value: alertLevel,
                onChanged: (val) {
                  setState(() {
                    alertLevel = val;
                    // Find the corresponding ID
                    if (val != null && alertLevelOptions.isNotEmpty) {
                      try {
                        final selectedLevel = alertLevelOptions.firstWhere(
                          (level) => level['name'] == val,
                          orElse: () => <String, dynamic>{},
                        );
                        if (selectedLevel.isNotEmpty) {
                          alertLevelId = selectedLevel['_id'];
                          print(
                            '✅ Selected alert level: $val with ID: $alertLevelId',
                          );
                        } else {
                          print('❌ Could not find alert level ID for: $val');
                          print(
                            '❌ Available options: ${alertLevelOptions.map((e) => e['name']).toList()}',
                          );
                          alertLevelId = null;
                        }
                      } catch (e) {
                        print('❌ Error finding alert level ID: $e');
                        alertLevelId = null;
                      }
                    } else {
                      alertLevelId = null;
                      print('🔍 Alert level cleared');
                    }
                  });
                },
              ),
              const SizedBox(height: 10),

              // // Show file selection status
              // if (_hasFilesToUpload()) ...[
              //   Container(
              //     padding: const EdgeInsets.all(12),
              //     margin: const EdgeInsets.only(bottom: 10),
              //     decoration: BoxDecoration(
              //       color: Colors.green.shade50,
              //       border: Border.all(color: Colors.green.shade200),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Row(
              //   children: [
              //         Icon(Icons.file_upload, color: Colors.green.shade600),
              //         const SizedBox(width: 8),
              //     Expanded(
              //           child: Text(
              //             _getFileCountText(),
              //             style: TextStyle(
              //               color: Colors.green.shade700,
              //               fontWeight: FontWeight.w500,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ],

              // if (uploadStatus.isNotEmpty) ...[
              //   Container(
              //     padding: const EdgeInsets.all(12),
              //     margin: const EdgeInsets.only(bottom: 10),
              //     decoration: BoxDecoration(
              //       color: Colors.blue.shade50,
              //       border: Border.all(color: Colors.blue.shade200),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Row(
              //       children: [
              //         Icon(Icons.info_outline, color: Colors.blue.shade600),
              //         const SizedBox(width: 8),
              //     Expanded(
              //           child: Text(
              //             uploadStatus,
              //             style: TextStyle(
              //               color: Colors.blue.shade700,
              //               fontWeight: FontWeight.w500,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              //   ),
              // ],

              // // Debug button to test connectivity
              // if (!isUploading) ...[
              //   Container(
              //     margin: const EdgeInsets.only(bottom: 10),
              //     child: CustomButton(
              //       text: 'Test Backend Connection',
              //       onPressed: () async {
              //         await _testBackendConnectivity();
              //       },
              //       fontWeight: FontWeight.normal,
              //     ),
              //   ),
              // ],
              CustomButton(
                text: isUploading ? 'Submitting...' : 'Submit',
                onPressed: isUploading
                    ? null
                    : () async {
                        if (_validateForm()) {
                          await _submitFinalReport();
                        }
                      },
                fontWeight: FontWeight.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:security_alert/screens/scam/scam_report_service.dart';
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import '../../services/jwt_service.dart';
// import '../../services/token_storage.dart';
// import '../../models/scam_report_model.dart';
// import '../../custom/customButton.dart';
// import '../../custom/customDropdown.dart';
// import '../../custom/Success_page.dart';
// import '../../services/api_service.dart';
// import '../../custom/fileUpload.dart';

// class ReportScam2 extends StatefulWidget {
//   final ScamReportModel report;
//   const ReportScam2({required this.report});

//   @override
//   State<ReportScam2> createState() => _ReportScam2State();
// }

// class _ReportScam2State extends State<ReportScam2> {
//   final _formKey = GlobalKey<FormState>();
//   String? alertLevel;
//   String? alertLevelId; // Add alert level ID
//   final List<String> alertLevels = ['Low', 'Medium', 'High', 'Critical'];
//   List<Map<String, dynamic>> alertLevelOptions =
//       []; // Store alert level options from API
//   bool isUploading = false;
//   String uploadStatus = '';
//   Map<String, dynamic>? uploadedFilesData;
//   bool filesUploaded = false;
//   String? selectedAddress; // Add selected address variable

//   final GlobalKey<FileUploadWidgetState> _fileUploadKey =
//       GlobalKey<FileUploadWidgetState>(
//         debugLabel: 'scam_file_upload_${DateTime.now().millisecondsSinceEpoch}',
//       );

//   @override
//   void initState() {
//     super.initState();
//     alertLevel = widget.report.alertLevels;
//     _loadAlertLevels();

//     // Debug: Print received data

//     print('🔍 - Report JSON: ${widget.report.toJson()}');
//   }

//   Future<void> _loadAlertLevels() async {
//     try {
//       // Try to fetch alert levels from backend
//       try {
//         final apiService = ApiService();
//         final alertLevels = await apiService.fetchAlertLevels();

//         if (alertLevels.isNotEmpty) {
//           if (mounted) {
//             setState(() {
//               alertLevelOptions = alertLevels;
//             });

//             print(
//               '🔍 Alert levels: ${alertLevels.map((level) => '${level['name']} (${level['_id']})').join(', ')}',
//             );
//           }
//         } else {
//           throw Exception('No alert levels returned from API');
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to load alert levels from server. Please check your connection and try again.',
//               ),
//               backgroundColor: Colors.orange,
//               duration: Duration(seconds: 5),
//             ),
//           );
//         }
//       }
//     } catch (e) {}
//   }

//   // Debug method to test backend connectivity
//   Future<void> _testBackendConnectivity() async {
//     try {
//       // Test 1: Check if we can reach the backend
//       final connectivity = await Connectivity().checkConnectivity();
//       final isOnline = connectivity != ConnectivityResult.none;

//       if (!isOnline) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('No internet connection detected'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         return;
//       }

//       // Test 2: Check authentication token
//       final token = await TokenStorage.getAccessToken();
//       print(
//         '🔐 Authentication token: ${token != null && token.isNotEmpty ? 'Present' : 'Not present'}',
//       );

//       if (token == null || token.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Authentication token not found'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }

//       // Test 3: Try a simple API call
//       try {
//         final response = await ApiService().fetchAllReports();
//         print(
//           '✅ Backend API test successful: ${response.length} reports found',
//         );
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   SnackBar(
//         //     content: Text(
//         //       'Backend connection successful! Found ${response.length} reports',
//         //     ),
//         //     backgroundColor: Colors.green,
//         //   ),
//         // );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Backend connection failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Connectivity test failed: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _submitFinalReport() async {
//     if (alertLevel == null || alertLevel!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please select an alert severity level'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       isUploading = true;
//       uploadStatus = 'Preparing report submission with auto-uploaded files...';
//     });

//     try {
//       // Test backend connectivity first
//       await _testBackendConnectivity();

//       // Use already uploaded files from FileUploadWidget (auto-upload enabled)
//       Map<String, dynamic> uploadedFiles = {
//         'screenshots': [],
//         'documents': [],
//         'voiceMessages': [],
//         'videofiles': [],
//       };

//       // Get uploaded files from FileUploadWidget state (auto-upload enabled)
//       if (_fileUploadKey.currentState != null) {
//         final state = _fileUploadKey.currentState!;

//         // Get the already uploaded files from the widget
//         uploadedFiles = state.getCurrentUploadedFiles();
//       } else {}

//       // Use categorized file objects for backend and URLs for local storage
//       final screenshotsForBackend =
//           (uploadedFiles['screenshots'] as List? ?? [])
//               .cast<Map<String, dynamic>>()
//               .toList();

//       final documentsForBackend = (uploadedFiles['documents'] as List? ?? [])
//           .cast<Map<String, dynamic>>()
//           .toList();

//       final voiceMessagesForBackend =
//           (uploadedFiles['voiceMessages'] as List? ?? [])
//               .cast<Map<String, dynamic>>()
//               .toList();
//       final videoMessagesForBackend =
//           (uploadedFiles['videofiles'] as List? ?? [])
//               .cast<Map<String, dynamic>>()
//               .toList();

//       // Extract URLs for local model storage
//       final screenshots = screenshotsForBackend
//           .map((f) => f['url']?.toString() ?? '')
//           .where((url) => url.isNotEmpty)
//           .toList();

//       final documents = documentsForBackend
//           .map((f) => f['url']?.toString() ?? '')
//           .where((url) => url.isNotEmpty)
//           .toList();

//       final voiceMessages = voiceMessagesForBackend
//           .map((f) => f['url']?.toString() ?? '')
//           .where((url) => url.isNotEmpty)
//           .toList();
//       final videofiles = videoMessagesForBackend
//           .map((f) => f['url']?.toString() ?? '')
//           .where((url) => url.isNotEmpty)
//           .toList();

//       // Check connectivity
//       final connectivity = await Connectivity().checkConnectivity();
//       final isOnline = connectivity != ConnectivityResult.none;

//       // Validate alert level ID before submission
//       if (alertLevelId == null || alertLevelId!.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Please select an alert severity level'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         setState(() {
//           isUploading = false;
//         });
//         return;
//       }

//       // Prepare form data for backend submission - EXACT FORMAT MATCH
//       final formData = {
//         // Required fields with exact backend format
//         'reportCategoryId': widget.report.reportCategoryId,
//         'reportTypeId': widget.report.reportTypeId,
//         'alertLevels':
//             alertLevelId, // This should be the alert level ID, not name
//         'keycloackUserId':
//             await JwtService.getCurrentUserId() ??
//             widget.report.keycloakUserId ??
//             '',
//         'createdBy':
//             await JwtService.getCurrentUserEmail() ??
//             await JwtService.getCurrentUserId() ??
//             widget.report.keycloakUserId ??
//             '',
//         'isActive': true,
//         'location': await _getCurrentLocation(), // Dynamic coordinates
//         'phoneNumbers': widget.report.phoneNumbers ?? [],
//         'emails': widget.report.emailAddresses ?? [],
//         'mediaHandles': widget.report.socialMediaHandles ?? [],
//         'methodOfContact': widget.report.methodOfContactId ?? '',
//         'website': widget.report.website ?? '',
//         'currency': widget.report.currency ?? 'INR',
//         'moneyLost': widget.report.amountLost?.toString() ?? '0',
//         'reportOutcome': false,
//         'description': widget.report.description ?? '',
//         'incidentDate':
//             widget.report.incidentDateTime?.toUtc().toIso8601String() ??
//             DateTime.now().toUtc().toIso8601String(),
//         'scammerName': widget.report.scammerName ?? '',
//         'screenshots': screenshotsForBackend,
//         'voiceMessages': voiceMessagesForBackend,
//         'documents': documentsForBackend,
//         'videofiles': videoMessagesForBackend,
//         'createdAt':
//             widget.report.createdAt?.toUtc().toIso8601String() ??
//             DateTime.now().toUtc().toIso8601String(),
//         'updatedAt': DateTime.now().toUtc().toIso8601String(),
//       };

//       print('🚀 Form data keys: ${formData.keys.toList()}');

//       print(
//         '🚀 Phone Numbers: ${formData['phoneNumbers']} (type: ${formData['phoneNumbers'].runtimeType})',
//       );
//       print(
//         '🚀 Emails: ${formData['emails']} (type: ${formData['emails'].runtimeType})',
//       );
//       print(
//         '🚀 Media Handles: ${formData['mediaHandles']} (type: ${formData['mediaHandles'].runtimeType})',
//       );

//       print(
//         '🚀 Media Handles from widget: ${widget.report.socialMediaHandles}',
//       );

//       // Validate arrays are not empty
//       if (widget.report.phoneNumbers?.isEmpty ?? true) {}
//       if (widget.report.emailAddresses?.isEmpty ?? true) {}
//       if (widget.report.socialMediaHandles?.isEmpty ?? true) {}

//       // Create updated report model with all data including uploaded files
//       final updatedReport = widget.report.copyWith(
//         alertLevels: alertLevel,
//         screenshotPaths: screenshots,
//         documentPaths: documents,
//         voiceRecordings: voiceMessages,
//         updatedAt: DateTime.now(),
//         isSynced: isOnline, // Mark as synced if online
//       );

//       // Save to local thread database first (offline-first approach)
//       setState(() {
//         uploadStatus = 'Saving to local database...';
//       });

//       final box = Hive.box<ScamReportModel>('scam_reports');

//       print('💾 Report to save: ${updatedReport.toJson()}');

//       if (updatedReport.isInBox) {
//         await ScamReportService.updateReport(updatedReport);
//       } else {
//         await ScamReportService.saveReportOffline(updatedReport);
//       }

//       // Verify the save by reading back the data
//       final allReports = box.values.toList();

//       if (allReports.isNotEmpty) {
//         final lastReport = allReports.last;
//         print('💾 Last saved report: ${lastReport.toJson()}');
//       }

//       // Additional verification - check if we can read the data back

//       final verificationBox = Hive.box<ScamReportModel>('scam_reports');
//       final allStoredReports = verificationBox.values.toList();

//       if (allStoredReports.isNotEmpty) {
//         final latestReport = allStoredReports.last;
//       }

//       // Test thread database visibility

//       await _testThreadDatabaseVisibility();

//       // Submit to backend if online - TEMPORARILY BYPASS CONNECTIVITY TEST
//       if (isOnline) {
//         try {
//           setState(() {
//             uploadStatus = 'Submitting to backend...';
//           });

//           print('🌐 Form data being sent: ${jsonEncode(formData)}');

//           await ApiService().submitScamReport(formData);

//           // Update local report to mark as synced
//           final syncedReport = updatedReport.copyWith(isSynced: true);
//           if (syncedReport.isInBox) {
//             await ScamReportService.updateReport(syncedReport);
//           } else {
//             await ScamReportService.saveReportOffline(syncedReport);
//           }

//           setState(() {
//             uploadStatus = 'Successfully saved to backend and local database!';
//           });
//         } catch (e) {
//           setState(() {
//             uploadStatus =
//                 'Saved locally, but backend sync failed. Will retry later.';
//           });
//         }
//       } else {
//         setState(() {
//           uploadStatus = 'Saved to local database. Will sync when online.';
//         });
//       }

//       setState(() {
//         isUploading = false;
//       });

//       // Show success message and navigate
//       if (mounted) {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const ReportSuccess(label: 'Scam Report'),
//           ),
//           (route) => false,
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               isOnline
//                   ? 'Scam report successfully submitted and saved locally!'
//                   : 'Scam report saved locally. Will sync when online.',
//             ),
//             duration: Duration(seconds: 3),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e, stack) {
//       setState(() {
//         isUploading = false;
//         uploadStatus = '';
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting report: $e'),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 5),
//         ),
//       );
//     }
//   }

//   // Add method to validate form before submission
//   bool _validateForm() {
//     if (alertLevel == null || alertLevel!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please select an alert severity level'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return false;
//     }
//     return true;
//   }

//   // Add method to get current location dynamically
//   Future<Map<String, dynamic>> _getCurrentLocation() async {
//     try {
//       // Check if location services are enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         return {
//           'type': 'Point',
//           'coordinates': [0.0, 0.0], // Fallback coordinates
//           'address': 'Location services disabled',
//         };
//       }

//       // Check location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           return {
//             'type': 'Point',
//             'coordinates': [0.0, 0.0], // Fallback coordinates
//             'address': 'Location permission denied',
//           };
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         return {
//           'type': 'Point',
//           'coordinates': [0.0, 0.0], // Fallback coordinates
//           'address': 'Location permission denied',
//         };
//       }

//       // Get current position
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10),
//       );

//       // Get real address using geocoding
//       String address =
//           selectedAddress ?? '${position.latitude}, ${position.longitude}';

//       // If no selected address, try to get real address from coordinates
//       if (selectedAddress == null) {
//         try {
//           List<Placemark> placemarks = await placemarkFromCoordinates(
//             position.latitude,
//             position.longitude,
//           );

//           if (placemarks.isNotEmpty) {
//             Placemark placemark = placemarks[0];
//             address = [
//               placemark.street,
//               placemark.subLocality,
//               placemark.locality,
//               placemark.administrativeArea,
//               placemark.country,
//             ].where((e) => e != null && e.isNotEmpty).join(', ');
//           }
//         } catch (e) {
//           // Keep the coordinates as fallback
//           address = '${position.latitude}, ${position.longitude}';
//         }
//       }

//       return {
//         'type': 'Point',
//         'coordinates': [
//           position.longitude,
//           position.latitude,
//         ], // [lng, lat] format
//         'address': address,
//       };
//     } catch (e) {
//       return {
//         'type': 'Point',
//         'coordinates': [0.0, 0.0], // Fallback coordinates
//         'address': 'Location error',
//       };
//     }
//   }

//   // Add a test method to verify thread database visibility
//   Future<void> _testThreadDatabaseVisibility() async {
//     final box = Hive.box<ScamReportModel>('scam_reports');
//     final allReports = box.values.toList();

//     if (allReports.isNotEmpty) {
//       final latestReport = allReports.last;
//     } else {}
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Upload Evidence')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               FileUploadWidget(
//                 key: _fileUploadKey,
//                 config: FileUploadConfig(
//                   reportType: 'scam',
//                   reportId:
//                       widget.report.id ?? FileUploadService.generateObjectId(),
//                   autoUpload: true, // Enable auto-upload
//                   showProgress: true,
//                   allowMultipleFiles: true,
//                 ),
//                 onFilesUploaded: (files) {
//                   setState(() {
//                     uploadedFilesData = files;
//                     filesUploaded = true;
//                   });
//                   // ScaffoldMessenger.of(context).showSnackBar(
//                   //   SnackBar(
//                   //     content: Text('Files uploaded successfully!'),
//                   //     backgroundColor: Colors.green,
//                   //   ),
//                   // );
//                 },
//                 onError: (error) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('File upload error: $error'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 20),
//               CustomDropdown(
//                 label: 'Alert Severity *',
//                 hint: 'Select severity (Required)',
//                 items: alertLevelOptions.isNotEmpty
//                     ? alertLevelOptions
//                           .map((level) => level['name'] as String)
//                           .toList()
//                     : alertLevels,
//                 value: alertLevel,
//                 onChanged: (val) {
//                   setState(() {
//                     alertLevel = val;
//                     // Find the corresponding ID
//                     if (val != null && alertLevelOptions.isNotEmpty) {
//                       try {
//                         final selectedLevel = alertLevelOptions.firstWhere(
//                           (level) => level['name'] == val,
//                           orElse: () => <String, dynamic>{},
//                         );
//                         if (selectedLevel.isNotEmpty) {
//                           alertLevelId = selectedLevel['_id'];
//                           print(
//                             '✅ Selected alert level: $val with ID: $alertLevelId',
//                           );
//                         } else {
//                           print(
//                             '❌ Available options: ${alertLevelOptions.map((e) => e['name']).toList()}',
//                           );
//                           alertLevelId = null;
//                         }
//                       } catch (e) {
//                         alertLevelId = null;
//                       }
//                     } else {
//                       alertLevelId = null;
//                     }
//                   });
//                 },
//               ),
//               const SizedBox(height: 10),

//               // // Show file selection status
//               // if (_hasFilesToUpload()) ...[
//               //   Container(
//               //     padding: const EdgeInsets.all(12),
//               //     margin: const EdgeInsets.only(bottom: 10),
//               //     decoration: BoxDecoration(
//               //       color: Colors.green.shade50,
//               //       border: Border.all(color: Colors.green.shade200),
//               //       borderRadius: BorderRadius.circular(8),
//               //     ),
//               //     child: Row(
//               //   children: [
//               //         Icon(Icons.file_upload, color: Colors.green.shade600),
//               //         const SizedBox(width: 8),
//               //     Expanded(
//               //           child: Text(
//               //             _getFileCountText(),
//               //             style: TextStyle(
//               //               color: Colors.green.shade700,
//               //               fontWeight: FontWeight.w500,
//               //             ),
//               //           ),
//               //         ),
//               //       ],
//               //     ),
//               //   ),
//               // ],

//               // if (uploadStatus.isNotEmpty) ...[
//               //   Container(
//               //     padding: const EdgeInsets.all(12),
//               //     margin: const EdgeInsets.only(bottom: 10),
//               //     decoration: BoxDecoration(
//               //       color: Colors.blue.shade50,
//               //       border: Border.all(color: Colors.blue.shade200),
//               //       borderRadius: BorderRadius.circular(8),
//               //     ),
//               //     child: Row(
//               //       children: [
//               //         Icon(Icons.info_outline, color: Colors.blue.shade600),
//               //         const SizedBox(width: 8),
//               //     Expanded(
//               //           child: Text(
//               //             uploadStatus,
//               //             style: TextStyle(
//               //               color: Colors.blue.shade700,
//               //               fontWeight: FontWeight.w500,
//               //         ),
//               //       ),
//               //     ),
//               //   ],
//               // ),
//               //   ),
//               // ],

//               // // Debug button to test connectivity
//               // if (!isUploading) ...[
//               //   Container(
//               //     margin: const EdgeInsets.only(bottom: 10),
//               //     child: CustomButton(
//               //       text: 'Test Backend Connection',
//               //       onPressed: () async {
//               //         await _testBackendConnectivity();
//               //       },
//               //       fontWeight: FontWeight.normal,
//               //     ),
//               //   ),
//               // ],
//               CustomButton(
//                 text: isUploading ? 'Uploading...' : 'Submit',
//                 onPressed: isUploading
//                     ? null
//                     : () async {
//                         if (_validateForm()) {
//                           await _submitFinalReport();
//                         }
//                       },
//                 fontWeight: FontWeight.normal,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:hive/hive.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:security_alert/screens/scam/scam_report_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import '../../services/jwt_service.dart';
// import '../../services/token_storage.dart';
// import '../../models/scam_report_model.dart';
// import '../../custom/customButton.dart';
// import '../../custom/customDropdown.dart';
// import '../../custom/Success_page.dart';
// import '../../services/api_service.dart';
// import '../../custom/fileUpload.dart';

// class ReportScam2 extends StatefulWidget {
//   final ScamReportModel report;
//   const ReportScam2({required this.report});

//   @override
//   State<ReportScam2> createState() => _ReportScam2State();
// }

// class _ReportScam2State extends State<ReportScam2> {
//   final _formKey = GlobalKey<FormState>();
//   String? alertLevel;
//   String? alertLevelId; // Add alert level ID
//   final List<String> alertLevels = ['Low', 'Medium', 'High', 'Critical'];
//   List<Map<String, dynamic>> alertLevelOptions =
//       []; // Store alert level options from API
//   bool isUploading = false;
//   String uploadStatus = '';
//   Map<String, dynamic>? uploadedFilesData;
//   bool filesUploaded = false;
//   String? selectedAddress; // Add selected address variable

//   final GlobalKey<FileUploadWidgetState> _fileUploadKey =
//       GlobalKey<FileUploadWidgetState>(debugLabel: 'scam_file_upload');

//   @override
//   void initState() {
//     super.initState();
//     alertLevel = widget.report.alertLevels;
//     _loadAlertLevels();

//     // Debug: Print received data
//     print('🔍 Received report data in Step 2:');
//     print('🔍 - Phone Numbers: ${widget.report.phoneNumbers}');
//     print('🔍 - Email Addresses: ${widget.report.emailAddresses}');
//     print('🔍 - Social Media Handles: ${widget.report.socialMediaHandles}');
//     print('🔍 - Report ID: ${widget.report.id}');
//     print('🔍 - Report JSON: ${widget.report.toJson()}');
//   }

//   Future<void> _loadAlertLevels() async {
//     try {
//       print('🔍 Loading alert levels from API...');

//       // Try to fetch alert levels from backend
//       try {
//         final apiService = ApiService();
//         final alertLevels = await apiService.fetchAlertLevels();

//         if (alertLevels.isNotEmpty) {
//           if (mounted) {
//             setState(() {
//               alertLevelOptions = alertLevels;
//             });
//             print('🔍 Loaded ${alertLevels.length} alert levels from API');
//             print(
//               '🔍 Alert levels: ${alertLevels.map((level) => '${level['name']} (${level['_id']})').join(', ')}',
//             );
//           }
//         } else {
//           throw Exception('No alert levels returned from API');
//         }
//       } catch (e) {
//         print('❌ Error loading alert levels from API: $e');
//         print('🔍 Showing error message to user...');

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'Failed to load alert levels from server. Please check your connection and try again.',
//               ),
//               backgroundColor: Colors.orange,
//               duration: Duration(seconds: 5),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       print('❌ Error loading alert levels: $e');
//     }
//   }

//   // Debug method to test backend connectivity
//   Future<void> _testBackendConnectivity() async {
//     print('🧪 Testing backend connectivity...');

//     try {
//       // Test 1: Check if we can reach the backend
//       final connectivity = await Connectivity().checkConnectivity();
//       final isOnline = connectivity != ConnectivityResult.none;
//       print('🌐 Network connectivity: ${isOnline ? 'Online' : 'Offline'}');

//       if (!isOnline) {
//         print('❌ No internet connection');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('No internet connection detected'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         return;
//       }

//       // Test 2: Check authentication token
//       final token = await TokenStorage.getAccessToken();
//       print(
//         '🔐 Authentication token: ${token != null && token.isNotEmpty ? 'Present' : 'Not present'}',
//       );

//       if (token == null || token.isEmpty) {
//         print('❌ No authentication token found');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Authentication token not found'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }

//       // Test 3: Try a simple API call
//       try {
//         final response = await ApiService().fetchAllReports();
//         print(
//           '✅ Backend API test successful: ${response.length} reports found',
//         );
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Backend connection successful! Found ${response.length} reports',
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } catch (e) {
//         print('❌ Backend API test failed: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Backend connection failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       print('❌ Backend connectivity test failed: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Connectivity test failed: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _submitFinalReport() async {
//     print('🚀 Starting scam report submission...');
//     print('🚀 Alert level: $alertLevel');
//     print('🚀 Report ID: ${widget.report.id}');
//     print('🚀 Report type: ${widget.report.reportTypeId}');

//     if (alertLevel == null || alertLevel!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please select an alert severity level'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       isUploading = true;
//       uploadStatus = 'Preparing files for upload...';
//     });

//     try {
//       // Test backend connectivity first
//       await _testBackendConnectivity();

//       Map<String, dynamic> uploadedFiles = {
//         'screenshots': [],
//         'documents': [],
//         'voiceMessages': [],
//       };

//       // Upload files if any are selected
//       if (_fileUploadKey.currentState != null) {
//         final state = _fileUploadKey.currentState!;
//         print('🚀 File upload state found');
//         print('🚀 Selected images: ${state.selectedImages.length}');
//         print('🚀 Selected documents: ${state.selectedDocuments.length}');
//         print('🚀 Selected voice files: ${state.selectedVoiceFiles.length}');

//         if (state.selectedImages.isNotEmpty ||
//             state.selectedDocuments.isNotEmpty ||
//             state.selectedVoiceFiles.isNotEmpty) {
//           setState(() {
//             uploadStatus = 'Uploading files to backend...';
//           });

//           print('🚀 Starting file upload during submit...');
//           try {
//             // Upload files only during submit, not automatically
//             uploadedFiles = await state.triggerUpload();
//             print('🚀 File upload completed during submit');
//             print('🚀 Uploaded files: $uploadedFiles');

//             setState(() {
//               uploadedFilesData = uploadedFiles;
//               filesUploaded = true;
//               uploadStatus = 'Files uploaded successfully!';
//             });
//           } catch (e) {
//             print('⚠️ File upload failed: $e');
//             print('⚠️ Continuing with report submission without files...');
//             setState(() {
//               uploadStatus =
//                   'File upload failed, continuing with report submission...';
//             });
//             // Continue with empty files
//             uploadedFiles = {
//               'screenshots': [],
//               'documents': [],
//               'voiceMessages': [],
//             };
//           }
//         } else {
//           print('🚀 No files selected for upload');
//         }
//       } else {
//         print('🚀 File upload state not found');
//       }

//       // Use categorized file objects for backend and URLs for local storage
//       final screenshotsForBackend =
//           (uploadedFiles['screenshots'] as List? ?? [])
//               .cast<Map<String, dynamic>>()
//               .toList();

//       final documentsForBackend = (uploadedFiles['documents'] as List? ?? [])
//           .cast<Map<String, dynamic>>()
//           .toList();

//       final voiceMessagesForBackend =
//           (uploadedFiles['voiceMessages'] as List? ?? [])
//               .cast<Map<String, dynamic>>()
//               .toList();

//       // Extract URLs for local model storage
//       final screenshots = screenshotsForBackend
//           .map((f) => f['url']?.toString() ?? '')
//           .where((url) => url.isNotEmpty)
//           .toList();

//       final documents = documentsForBackend
//           .map((f) => f['url']?.toString() ?? '')
//           .where((url) => url.isNotEmpty)
//           .toList();

//       final voiceMessages = voiceMessagesForBackend
//           .map((f) => f['url']?.toString() ?? '')
//           .where((url) => url.isNotEmpty)
//           .toList();

//       print('🚀 Extracted file URLs:');
//       print('🚀 - Screenshots: ${screenshots.length}');
//       print('🚀 - Documents: ${documents.length}');
//       print('🚀 - Voice messages: ${voiceMessages.length}');

//       // Check connectivity
//       final connectivity = await Connectivity().checkConnectivity();
//       final isOnline = connectivity != ConnectivityResult.none;
//       print('🚀 Connectivity status: ${isOnline ? 'Online' : 'Offline'}');

//       // Validate alert level ID before submission
//       if (alertLevelId == null || alertLevelId!.isEmpty) {
//         print('❌ Alert level ID is null or empty');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Please select an alert severity level'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         setState(() {
//           isUploading = false;
//         });
//         return;
//       }

//       print('✅ Alert level ID validated: $alertLevelId');

//       // Prepare form data for backend submission - EXACT FORMAT MATCH
//       final formData = {
//         // Required fields with exact backend format
//         'reportCategoryId': widget.report.reportCategoryId,
//         'reportTypeId': widget.report.reportTypeId,
//         'alertLevels':
//             alertLevelId, // This should be the alert level ID, not name
//         'keycloackUserId':
//             await JwtService.getCurrentUserId() ??
//             widget.report.keycloakUserId ??
//             '',
//         'createdBy':
//             await JwtService.getCurrentUserEmail() ??
//             await JwtService.getCurrentUserId() ??
//             widget.report.keycloakUserId ??
//             '',
//         'isActive': true,
//         'location': await _getCurrentLocation(), // Dynamic coordinates
//         'phoneNumbers': widget.report.phoneNumbers ?? [],
//         'emails': widget.report.emailAddresses ?? [],
//         'mediaHandles': widget.report.socialMediaHandles ?? [],
//         'methodOfContact': widget.report.methodOfContactId ?? '',
//         'website': widget.report.website ?? '',
//         'currency': widget.report.currency ?? 'INR',
//         'moneyLost': widget.report.amountLost?.toString() ?? '0',
//         'reportOutcome': false,
//         'description': widget.report.description ?? '',
//         'incidentDate':
//             widget.report.incidentDateTime?.toIso8601String() ??
//             DateTime.now().toIso8601String(),
//         'scammerName': widget.report.scammerName ?? '',
//         'screenshots': screenshotsForBackend,
//         'voiceMessages': voiceMessagesForBackend,
//         'documents': documentsForBackend,
//         'createdAt':
//             widget.report.createdAt?.toIso8601String() ??
//             DateTime.now().toIso8601String(),
//         'updatedAt': DateTime.now().toIso8601String(),
//       };

//       print('🚀 Form data prepared for backend submission');
//       print('🚀 Form data keys: ${formData.keys.toList()}');
//       print('🚀 Report Category ID: ${formData['reportCategoryId']}');
//       print('🚀 Report Type ID: ${formData['reportTypeId']}');
//       print('🚀 Alert Levels: ${formData['alertLevels']}');
//       print('🚀 Keycloak User ID: ${formData['keycloackUserId']}');
//       print('🚀 Created By: ${formData['createdBy']}');
//       print(
//         '🚀 Phone Numbers: ${formData['phoneNumbers']} (type: ${formData['phoneNumbers'].runtimeType})',
//       );
//       print(
//         '🚀 Emails: ${formData['emails']} (type: ${formData['emails'].runtimeType})',
//       );
//       print(
//         '🚀 Media Handles: ${formData['mediaHandles']} (type: ${formData['mediaHandles'].runtimeType})',
//       );
//       print('🚀 Phone Numbers from widget: ${widget.report.phoneNumbers}');
//       print('🚀 Emails from widget: ${widget.report.emailAddresses}');
//       print(
//         '🚀 Media Handles from widget: ${widget.report.socialMediaHandles}',
//       );

//       // Validate arrays are not empty
//       if (widget.report.phoneNumbers?.isEmpty ?? true) {
//         print('⚠️ Warning: Phone numbers array is empty');
//       }
//       if (widget.report.emailAddresses?.isEmpty ?? true) {
//         print('⚠️ Warning: Email addresses array is empty');
//       }
//       if (widget.report.socialMediaHandles?.isEmpty ?? true) {
//         print('⚠️ Warning: Social media handles array is empty');
//       }
//       print('🚀 Screenshots: ${formData['screenshots']}');
//       print('🚀 Voice Messages: ${formData['voiceMessages']}');
//       print('🚀 Documents: ${formData['documents']}');

//       // Create updated report model with all data including uploaded files
//       final updatedReport = widget.report.copyWith(
//         alertLevels: alertLevel,
//         screenshotPaths: screenshots,
//         documentPaths: documents,
//         voiceRecordings: voiceMessages,
//         updatedAt: DateTime.now(),
//         isSynced: isOnline, // Mark as synced if online
//       );

//       print('🚀 Updated report model created');

//       // Save to local thread database first (offline-first approach)
//       setState(() {
//         uploadStatus = 'Saving to local database...';
//       });

//       print('💾 Starting local database save...');
//       final box = Hive.box<ScamReportModel>('scam_reports');
//       print('💾 Box length before save: ${box.length}');
//       print('💾 Report to save: ${updatedReport.toJson()}');

//       if (updatedReport.isInBox) {
//         await ScamReportService.updateReport(updatedReport);
//         print('✅ Updated existing report in local database');
//       } else {
//         await ScamReportService.saveReportOffline(updatedReport);
//         print('✅ Saved new report to local database');
//       }

//       print('💾 Box length after save: ${box.length}');

//       // Verify the save by reading back the data
//       final allReports = box.values.toList();
//       print('💾 Total reports in database: ${allReports.length}');
//       if (allReports.isNotEmpty) {
//         final lastReport = allReports.last;
//         print('💾 Last saved report: ${lastReport.toJson()}');
//       }

//       // Additional verification - check if we can read the data back
//       print('🔍 Verifying data persistence...');
//       final verificationBox = Hive.box<ScamReportModel>('scam_reports');
//       final allStoredReports = verificationBox.values.toList();
//       print('🔍 Total reports after save: ${allStoredReports.length}');

//       if (allStoredReports.isNotEmpty) {
//         final latestReport = allStoredReports.last;
//         print('🔍 Latest report details:');
//         print('🔍 - ID: ${latestReport.id}');
//         print('🔍 - Description: ${latestReport.description}');
//         print('🔍 - Alert Level: ${latestReport.alertLevels}');
//         print('🔍 - Created At: ${latestReport.createdAt}');
//         print('🔍 - Is Synced: ${latestReport.isSynced}');
//         print('🔍 - Screenshot Paths: ${latestReport.screenshotPaths}');
//         print('🔍 - Document Paths: ${latestReport.documentPaths}');
//       }

//       // Test thread database visibility
//       print('🧪 Testing thread database visibility...');
//       await _testThreadDatabaseVisibility();

//       // Submit to backend if online - TEMPORARILY BYPASS CONNECTIVITY TEST
//       if (isOnline) {
//         try {
//           setState(() {
//             uploadStatus = 'Submitting to backend...';
//           });

//           print('🌐 Starting backend submission...');
//           print('🌐 Form data being sent: ${jsonEncode(formData)}');

//           await ApiService().submitScamReport(formData);
//           print('✅ Backend submission successful');

//           // Update local report to mark as synced
//           final syncedReport = updatedReport.copyWith(isSynced: true);
//           if (syncedReport.isInBox) {
//             await ScamReportService.updateReport(syncedReport);
//             print('✅ Updated local report as synced');
//           } else {
//             await ScamReportService.saveReportOffline(syncedReport);
//             print('✅ Saved synced report to local database');
//           }

//           setState(() {
//             uploadStatus = 'Successfully saved to backend and local database!';
//           });
//         } catch (e) {
//           print('❌ Error syncing with backend: $e');
//           print('❌ Error stack trace: ${StackTrace.current}');
//           setState(() {
//             uploadStatus =
//                 'Saved locally, but backend sync failed. Will retry later.';
//           });
//         }
//       } else {
//         setState(() {
//           uploadStatus = 'Saved to local database. Will sync when online.';
//         });
//         print('📱 Offline mode - report saved locally for later sync');
//       }

//       setState(() {
//         isUploading = false;
//       });

//       // Show success message and navigate
//       if (mounted) {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const ReportSuccess(label: 'Scam Report'),
//           ),
//           (route) => false,
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               isOnline
//                   ? 'Scam report successfully submitted and saved locally!'
//                   : 'Scam report saved locally. Will sync when online.',
//             ),
//             duration: Duration(seconds: 3),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e, stack) {
//       print('❌ Submission failed: $e\n$stack');
//       setState(() {
//         isUploading = false;
//         uploadStatus = '';
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting report: $e'),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 5),
//         ),
//       );
//     }
//   }

//   Future<void> _ensureFilesSelected() async {
//     if (_fileUploadKey.currentState != null) {
//       final state = _fileUploadKey.currentState!;

//       if (state.selectedImages.isEmpty &&
//           state.selectedDocuments.isEmpty &&
//           state.selectedVoiceFiles.isEmpty) {
//         final shouldSelectFiles = await showDialog<bool>(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text('No Files Selected'),
//             content: Text(
//               'Would you like to select files before submitting the report?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: Text('Submit Without Files'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: Text('Select Files'),
//               ),
//             ],
//           ),
//         );

//         if (shouldSelectFiles == true) {
//           try {
//             final images = await ImagePicker().pickMultiImage();
//             if (images != null) {
//               setState(() {
//                 state.selectedImages.addAll(images.map((e) => File(e.path)));
//               });
//             }

//             final documents = await FilePicker.platform.pickFiles(
//               allowMultiple: true,
//               type: FileType.custom,
//               allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
//             );

//             if (documents != null) {
//               setState(() {
//                 state.selectedDocuments.addAll(
//                   documents.paths.whereType<String>().map((path) => File(path)),
//                 );
//               });
//             }
//           } catch (e) {
//             print('❌ Error selecting files: $e');
//           }
//         }
//       }
//     }
//   }

//   // Add method to check if files are ready for upload
//   bool _hasFilesToUpload() {
//     if (_fileUploadKey.currentState != null) {
//       final state = _fileUploadKey.currentState!;
//       return state.selectedImages.isNotEmpty ||
//           state.selectedDocuments.isNotEmpty ||
//           state.selectedVoiceFiles.isNotEmpty;
//     }
//     return false;
//   }

//   // Add method to get file count for display
//   String _getFileCountText() {
//     if (_fileUploadKey.currentState != null) {
//       final state = _fileUploadKey.currentState!;
//       final totalFiles =
//           state.selectedImages.length +
//           state.selectedDocuments.length +
//           state.selectedVoiceFiles.length;

//       if (totalFiles == 0) return '';

//       List<String> parts = [];
//       if (state.selectedImages.isNotEmpty) {
//         parts.add('${state.selectedImages.length} image(s)');
//       }
//       if (state.selectedDocuments.isNotEmpty) {
//         parts.add('${state.selectedDocuments.length} document(s)');
//       }
//       if (state.selectedVoiceFiles.isNotEmpty) {
//         parts.add('${state.selectedVoiceFiles.length} voice file(s)');
//       }

//       return 'Selected: ${parts.join(', ')}';
//     }
//     return '';
//   }

//   // Add method to validate form before submission
//   bool _validateForm() {
//     if (alertLevel == null || alertLevel!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please select an alert severity level'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return false;
//     }
//     return true;
//   }

//   // Add method to get current location dynamically
//   Future<Map<String, dynamic>> _getCurrentLocation() async {
//     try {
//       print('📍 Getting current location...');

//       // Check if location services are enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         print('❌ Location services are disabled');
//         return {
//           'type': 'Point',
//           'coordinates': [0.0, 0.0], // Fallback coordinates
//           'address': 'Location services disabled',
//         };
//       }

//       // Check location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           print('❌ Location permission denied');
//           return {
//             'type': 'Point',
//             'coordinates': [0.0, 0.0], // Fallback coordinates
//             'address': 'Location permission denied',
//           };
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         print('❌ Location permission denied forever');
//         return {
//           'type': 'Point',
//           'coordinates': [0.0, 0.0], // Fallback coordinates
//           'address': 'Location permission denied',
//         };
//       }

//       // Get current position
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10),
//       );

//       print('✅ Location obtained: ${position.latitude}, ${position.longitude}');

//       // Get real address using geocoding
//       String address =
//           selectedAddress ?? '${position.latitude}, ${position.longitude}';

//       // If no selected address, try to get real address from coordinates
//       if (selectedAddress == null) {
//         try {
//           List<Placemark> placemarks = await placemarkFromCoordinates(
//             position.latitude,
//             position.longitude,
//           );

//           if (placemarks.isNotEmpty) {
//             Placemark placemark = placemarks[0];
//             address = [
//               placemark.street,
//               placemark.subLocality,
//               placemark.locality,
//               placemark.administrativeArea,
//               placemark.country,
//             ].where((e) => e != null && e.isNotEmpty).join(', ');
//           }
//         } catch (e) {
//           print('❌ Error getting address from coordinates: $e');
//           // Keep the coordinates as fallback
//         }
//       }

//       return {
//         'type': 'Point',
//         'coordinates': [
//           position.longitude,
//           position.latitude,
//         ], // [lng, lat] format
//         'address': address,
//       };
//     } catch (e) {
//       print('❌ Error getting location: $e');
//       return {
//         'type': 'Point',
//         'coordinates': [0.0, 0.0], // Fallback coordinates
//         'address': 'Location error',
//       };
//     }
//   }

//   // Add a test method to verify thread database visibility
//   Future<void> _testThreadDatabaseVisibility() async {
//     final box = Hive.box<ScamReportModel>('scam_reports');
//     final allReports = box.values.toList();
//     print('🧪 Thread Database Visibility Test:');
//     print('🧪 - Total reports in thread box: ${allReports.length}');
//     if (allReports.isNotEmpty) {
//       final latestReport = allReports.last;
//       print('🧪 - Latest report in thread box:');
//       print('🧪   - ID: ${latestReport.id}');
//       print('🧪   - Description: ${latestReport.description}');
//       print('🧪   - Alert Level: ${latestReport.alertLevels}');
//       print('🧪   - Created At: ${latestReport.createdAt}');
//       print('🧪   - Is Synced: ${latestReport.isSynced}');
//       print('🧪   - Screenshot Paths: ${latestReport.screenshotPaths}');
//       print('🧪   - Document Paths: ${latestReport.documentPaths}');
//     } else {
//       print('🧪 - No reports found in thread box.');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Upload Evidence')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               FileUploadWidget(
//                 key: _fileUploadKey,
//                 config: FileUploadConfig(
//                   reportType: 'scam',
//                   reportId:
//                       widget.report.id ?? FileUploadService.generateObjectId(),
//                   autoUpload: false, // Disable auto-upload
//                   showProgress: true,
//                   allowMultipleFiles: true,
//                 ),
//                 onFilesUploaded: (files) {
//                   setState(() {
//                     uploadedFilesData = files;
//                     filesUploaded = true;
//                   });
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Files uploaded successfully!'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 },
//                 onError: (error) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('File upload error: $error'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 20),
//               CustomDropdown(
//                 label: 'Alert Severity *',
//                 hint: 'Select severity (Required)',
//                 items: alertLevelOptions.isNotEmpty
//                     ? alertLevelOptions
//                           .map((level) => level['name'] as String)
//                           .toList()
//                     : alertLevels,
//                 value: alertLevel,
//                 onChanged: (val) {
//                   setState(() {
//                     alertLevel = val;
//                     // Find the corresponding ID
//                     if (val != null && alertLevelOptions.isNotEmpty) {
//                       try {
//                         final selectedLevel = alertLevelOptions.firstWhere(
//                           (level) => level['name'] == val,
//                           orElse: () => <String, dynamic>{},
//                         );
//                         if (selectedLevel.isNotEmpty) {
//                           alertLevelId = selectedLevel['_id'];
//                           print(
//                             '✅ Selected alert level: $val with ID: $alertLevelId',
//                           );
//                         } else {
//                           print('❌ Could not find alert level ID for: $val');
//                           print(
//                             '❌ Available options: ${alertLevelOptions.map((e) => e['name']).toList()}',
//                           );
//                           alertLevelId = null;
//                         }
//                       } catch (e) {
//                         print('❌ Error finding alert level ID: $e');
//                         alertLevelId = null;
//                       }
//                     } else {
//                       alertLevelId = null;
//                       print('🔍 Alert level cleared');
//                     }
//                   });
//                 },
//               ),
//               const SizedBox(height: 10),

//               // Show file selection status
//               if (_hasFilesToUpload()) ...[
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   margin: const EdgeInsets.only(bottom: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade50,
//                     border: Border.all(color: Colors.green.shade200),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.file_upload, color: Colors.green.shade600),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           _getFileCountText(),
//                           style: TextStyle(
//                             color: Colors.green.shade700,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],

//               if (uploadStatus.isNotEmpty) ...[
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   margin: const EdgeInsets.only(bottom: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     border: Border.all(color: Colors.blue.shade200),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.info_outline, color: Colors.blue.shade600),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           uploadStatus,
//                           style: TextStyle(
//                             color: Colors.blue.shade700,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],

//               // Debug button to test connectivity
//               // if (!isUploading) ...[
//               //   Container(
//               //     margin: const EdgeInsets.only(bottom: 10),
//               //     child: CustomButton(
//               //       text: 'Test Backend Connection',
//               //       onPressed: () async {
//               //         await _testBackendConnectivity();
//               //       },
//               //       fontWeight: FontWeight.normal,
//               //     ),
//               //   ),
//               // ],
//               CustomButton(
//                 text: isUploading ? 'Uploading...' : 'Submit',
//                 onPressed: isUploading
//                     ? null
//                     : () async {
//                         if (_validateForm()) {
//                           await _submitFinalReport();
//                         }
//                       },
//                 fontWeight: FontWeight.normal,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
