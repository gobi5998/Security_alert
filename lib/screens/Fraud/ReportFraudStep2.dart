import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:security_alert/screens/Fraud/fraud_report_service.dart';

import '../../models/fraud_report_model.dart';

import '../../custom/customButton.dart';
import '../../custom/customDropdown.dart';
import '../../custom/Success_page.dart';
import '../../services/api_service.dart';
import '../../custom/fileUpload.dart';

class ReportFraudStep2 extends StatefulWidget {
  final FraudReportModel report;

  const ReportFraudStep2({required this.report});

  @override
  State<ReportFraudStep2> createState() => _ReportFraudStep2State();
}

class _ReportFraudStep2State extends State<ReportFraudStep2> {
  final _formKey = GlobalKey<FormState>();
  String? alertLevel;
  List<File> screenshots = [],
      documents = [],
      voiceMessage = [];
  final List<String> alertLevels = ['Low', 'Medium', 'High', 'Critical'];
  final ImagePicker picker = ImagePicker();
  bool isUploading = false;
  String? uploadStatus = '';

  final GlobalKey<FileUploadWidgetState> _fileUploadKey =
  GlobalKey<FileUploadWidgetState>(debugLabel: 'fraud_file_upload');

  @override
  void initState() {
    super.initState();
    // Initialize alert level with current value from report
    alertLevel = widget.report.alertLevels;
    print('🔍 Initializing fraud report with alert level: $alertLevel');

    // If no alert level is set, we'll capture it from user selection
    if (alertLevel == null || alertLevel!.isEmpty) {
      print('🔍 No alert level set, will capture from user selection');
    }
  }

  Future<void> _pickFiles(String type) async {
    List<String> extensions = [];
    switch (type) {
      case 'screenshot':
        final images = await picker.pickMultiImage();
        if (images != null) {
          setState(() => screenshots.addAll(images.map((e) => File(e.path))));
        }
        break;
      case 'document':
        extensions = ['pdf', 'doc', 'docx', 'txt'];
        break;
      case 'voice':
        extensions = ['mp3', 'wav', 'm4a'];
        break;
    }

    if (type != 'screenshot') {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (result != null) {
        setState(() {
          final files = result.paths.map((e) => File(e!)).toList();
          if (type == 'document') documents.addAll(files);
          if (type == 'voiceMessage') voiceMessage.addAll(files);
          if (type == 'screenshots') screenshots.addAll(files);
        });
      }
    }
  }

  Future<void> _submitFinalReport() async {
    print('🔍 SUBMIT DEBUG - Starting submission...');
    print('🔍 SUBMIT DEBUG - alertLevel variable: $alertLevel');
    print('🔍 SUBMIT DEBUG - alertLevel type: ${alertLevel.runtimeType}');
    print('🔍 SUBMIT DEBUG - alertLevel is null: ${alertLevel == null}');
    print('🔍 SUBMIT DEBUG - alertLevel is empty: ${alertLevel?.isEmpty}');

    // Validate alert level selection
    if (alertLevel == null || alertLevel!.isEmpty) {
      print('🔍 SUBMIT DEBUG - Alert level validation failed!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an alert severity level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🔍 SUBMIT DEBUG - Alert level validation passed: $alertLevel');
    print('🔍 User selected alert level: $alertLevel');
    print('🔍 User selected alert level: $alertLevel');

    try {
      // Upload files first
      Map<String, dynamic> uploadedFiles = {};
      if (_fileUploadKey.currentState != null) {
        uploadedFiles = await _fileUploadKey.currentState!.triggerUpload();
        print('📤 Upload completed. Files structure: $uploadedFiles');
        
        // Validate that files were uploaded
        final screenshots = uploadedFiles['screenshots'] as List? ?? [];
        final documents = uploadedFiles['documents'] as List? ?? [];
        final voiceMessages = uploadedFiles['voiceMessages'] as List? ?? [];
        
        print('📊 Upload validation:');
        print('  📸 Screenshots: ${screenshots.length}');
        print('  📄 Documents: ${documents.length}');
        print('  🎵 Voice Messages: ${voiceMessages.length}');
        
        if (screenshots.isEmpty && documents.isEmpty && voiceMessages.isEmpty) {
          print('⚠️  No files were uploaded');
        }
      }

      // Debug: Check if files were actually uploaded
      final uploadedScreenshots = uploadedFiles['screenshots'] as List? ?? [];
      final uploadedDocuments = uploadedFiles['documents'] as List? ?? [];
      final uploadedVoiceMessages = uploadedFiles['voiceMessages'] as List? ?? [];
      
      print('📊 Upload Summary:');
      print('  📸 Screenshots uploaded: ${uploadedScreenshots.length}');
      print('  📄 Documents uploaded: ${uploadedDocuments.length}');
      print('  🎵 Voice messages uploaded: ${uploadedVoiceMessages.length}');

      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      // Ensure alert level is properly set
      final finalAlertLevel = alertLevel ?? widget.report.alertLevels;

      print('🔍 SUBMIT DEBUG - alertLevel variable: $alertLevel');
      print(
        '🔍 SUBMIT DEBUG - widget.report.alertLevels: ${widget.report
            .alertLevels}',
      );
      print('🔍 SUBMIT DEBUG - finalAlertLevel: $finalAlertLevel');
      print(
        '🔍 SUBMIT DEBUG - finalAlertLevel type: ${finalAlertLevel.runtimeType}',
      );
      print(
        '🔍 SUBMIT DEBUG - finalAlertLevel is null: ${finalAlertLevel == null}',
      );
      print(
        '🔍 SUBMIT DEBUG - finalAlertLevel is empty: ${finalAlertLevel
            ?.isEmpty}',
      );

      // Validate that we have a proper alert level
      if (finalAlertLevel == null || finalAlertLevel.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select an alert severity level'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Extract URLs for local storage (backward compatibility)
      List<String> screenshotUrls = [];
      List<String> documentUrls = [];
      List<String> voiceMessageUrls = [];

      for (var file in uploadedScreenshots) {
        String fileUrl = file['url']?.toString() ?? '';
        if (fileUrl.isNotEmpty) {
          screenshotUrls.add(fileUrl);
        }
      }

      for (var file in uploadedDocuments) {
        String fileUrl = file['url']?.toString() ?? '';
        if (fileUrl.isNotEmpty) {
          documentUrls.add(fileUrl);
        }
      }

      for (var file in uploadedVoiceMessages) {
        String fileUrl = file['url']?.toString() ?? '';
        if (fileUrl.isNotEmpty) {
          voiceMessageUrls.add(fileUrl);
        }
      }

      // Create complete report data with file objects for backend
      final formData = {
        'reportCategoryId': widget.report.reportCategoryId,
        'reportTypeId': widget.report.reportTypeId,
        'alertLevels': finalAlertLevel ?? '',
        'keycloackUserId': widget.report.keycloakUserId,
        'status': 'draft',
        'phoneNumber': widget.report.phoneNumber,
        'email': widget.report.email,
        'website': widget.report.website,
        'description': widget.report.description,
        'name': widget.report.name ?? 'Anonymous',
        'isActive': true,
      };

      // Create complete report data with file objects for backend
      final completeReportData = FileUploadService.createReportData(
        formData: formData,
        fileData: uploadedFiles,
      );

      print('📋 Complete report data for backend:');
      print('  Report Category ID: ${completeReportData['reportCategoryId']}');
      print('  Report Type ID: ${completeReportData['reportTypeId']}');
      print('  Alert Level: ${completeReportData['alertLevels']}');
      print('  Email: ${completeReportData['email']}');
      print('  Description: ${completeReportData['description']}');
      print('  Screenshots: ${(completeReportData['screenshots'] as List).length} files');
      print('  Voice Messages: ${(completeReportData['voiceMessages'] as List).length} files');
      print('  Documents: ${(completeReportData['documents'] as List).length} files');
      
      // Debug: Print detailed file information
      print('📸 Screenshots details:');
      for (var file in completeReportData['screenshots'] as List) {
        print('  - ${file['fileName']}: ${file['url']}');
      }
      print('🎵 Voice Messages details:');
      for (var file in completeReportData['voiceMessages'] as List) {
        print('  - ${file['fileName']}: ${file['url']}');
      }
      print('📄 Documents details:');
      for (var file in completeReportData['documents'] as List) {
        print('  - ${file['fileName']}: ${file['url']}');
      }

      // Update local report model for backward compatibility
      final updatedReport = widget.report
        ..alertLevels = finalAlertLevel
        ..screenshots = screenshotUrls
        ..documents = documentUrls
        ..voiceMessages = voiceMessageUrls;

      print('🔍 Selected alert level: $alertLevel');
      print('🔍 Original report alert level: ${widget.report.alertLevels}');
      print('🔍 Updated report alert level: ${updatedReport.alertLevels}');
      print('🔍 Alert level type: ${alertLevel.runtimeType}');
      print(
        '🔍 Updated alert level type: ${updatedReport.alertLevels.runtimeType}',
      );

      // 1. Save locally (Always)
      try {
        await FraudReportService.updateReport(updatedReport);
      } catch (e) {
        print('Local save failed but continuing: $e');
      }

      // 2. If online, send to backend with complete file objects
      if (isOnline) {
        try {
          print('📤 Sending complete report data to backend...');
          print('📤 Report data structure: $completeReportData');
          
          // Final validation of report data
          print('🔍 Final validation of report data:');
          print('  Alert Level: ${completeReportData['alertLevels']}');
          print('  Report Category ID: ${completeReportData['reportCategoryId']}');
          print('  Report Type ID: ${completeReportData['reportTypeId']}');
          print('  Email: ${completeReportData['email']}');
          print('  Description: ${completeReportData['description']}');
          print('  Screenshots count: ${(completeReportData['screenshots'] as List).length}');
          print('  Voice Messages count: ${(completeReportData['voiceMessages'] as List).length}');
          print('  Documents count: ${(completeReportData['documents'] as List).length}');
          
          // Send the complete report data with file objects to backend
          await ApiService().submitFraudReport(completeReportData);
          
          print('✅ Backend response: submitted successfully with files');
          print('✅ Files sent to backend:');
          print('  📸 Screenshots: ${(completeReportData['screenshots'] as List).length}');
          print('  🎵 Voice Messages: ${(completeReportData['voiceMessages'] as List).length}');
          print('  📄 Documents: ${(completeReportData['documents'] as List).length}');
          
          updatedReport.isSynced = true;
          
          // Clone the object before updating to avoid HiveError
          final clonedReport = FraudReportModel(
            id: updatedReport.id,
            reportCategoryId: updatedReport.reportCategoryId,
            reportTypeId: updatedReport.reportTypeId,
            alertLevels: updatedReport.alertLevels,
            name: updatedReport.name,
            phoneNumber: updatedReport.phoneNumber,
            email: updatedReport.email,
            website: updatedReport.website,
            description: updatedReport.description,
            createdAt: updatedReport.createdAt,
            updatedAt: DateTime.now(),
            isSynced: true,
            screenshots: updatedReport.screenshots,
            documents: updatedReport.documents,
            voiceMessages: updatedReport.voiceMessages,
          );
          try {
            await FraudReportService.updateReport(clonedReport); // mark synced
          } catch (e) {
            print('Failed to mark as synced: $e');
          }
        } catch (e) {
          debugPrint('❌ Failed to sync now, will retry later: $e');
          print('❌ Error details: $e');
        }
      }

      // 3. Navigate to success page
      print('Navigating to success page...');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportSuccess(label: 'Fraud Report'),
          ),
              (route) => false,
        );
      }
    } catch (e, stack) {
      print('Error in _submitFinalReport: $e\n$stack');
      // Optionally show a snackbar or dialog
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
              Column(
                // children: [
                //   ListTile(
                //     leading: Image.asset('assets/image/document.png'),
                //     title: const Text('Add Screenshots'),
                //     subtitle: Text('Selected: /5'),
                //     // onTap: _pickScreenshots,
                //   ),
                // ],
              ),
              const SizedBox(height: 16),

              // Documents Section
              // Column(
              //   children: [
              //     ListTile(
              //       leading: Image.asset('assets/image/document.png'),
              //       title: const Text('Add Documents'),
              //       subtitle: Text('Selected:  files'),
              //       // onTap: _pickDocuments,
              //     ),
              //   ],
              // ),

              FileUploadWidget(
                  key: _fileUploadKey,
                  reportId: widget.report.id ?? '123',
                  fileType: 'fraud',
                  autoUpload: true,
                  onFilesUploaded: (Map<String, dynamic> uploadedFiles) {
                    // Handle uploaded files
                    final screenshots = uploadedFiles['screenshots'] as List? ?? [];
                    final documents = uploadedFiles['documents'] as List? ?? [];
                    final voiceMessages = uploadedFiles['voiceMessages'] as List? ?? [];
                    print('Files uploaded: ${screenshots.length} screenshots, ${documents.length} documents, ${voiceMessages.length} voice messages');
                  },
              ),
              CustomDropdown(
                label: 'Alert Severity',
                hint: 'Select severity',
                items: alertLevels,
                value: alertLevel,
                onChanged: (val) {
                  print('🔍 Alert level changed from "$alertLevel" to "$val"');
                  print('🔍 New value type: ${val.runtimeType}');
                  print('🔍 New value is null: ${val == null}');
                  print('🔍 New value is empty: ${val?.isEmpty}');
                  setState(() => alertLevel = val);
                },
              ),
              const SizedBox(height: 10),
              // Debug button to test alert level
              if (alertLevel != null)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Selected Alert Level: $alertLevel',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Test button to verify alert level
              ElevatedButton(
                onPressed: () {
                  print('🔍 TEST - Current alertLevel: $alertLevel');
                  print('🔍 TEST - alertLevel type: ${alertLevel.runtimeType}');
                  print('🔍 TEST - alertLevel is null: ${alertLevel == null}');
                  print(
                    '🔍 TEST - alertLevel is empty: ${alertLevel?.isEmpty}',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Alert Level: ${alertLevel ?? "Not selected"}',
                      ),
                      backgroundColor: alertLevel != null
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                },
                child: Text('Test Alert Level Selection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Submit',
                onPressed: _submitFinalReport,
                fontWeight: FontWeight.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
