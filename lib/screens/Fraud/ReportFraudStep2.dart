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
  List<File> screenshots = [], documents = [], voices = [];
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
          if (type == 'voice') voices.addAll(files);
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

    try {
      // Upload files first
      List<Map<String, dynamic>> uploadedFiles = [];
      if (_fileUploadKey.currentState != null) {
        uploadedFiles = await _fileUploadKey.currentState!.triggerUpload();
      }

      // Categorize uploaded files
      List<String> screenshotUrls = [];
      List<String> documentUrls = [];

      for (var file in uploadedFiles) {
        String fileName = file['fileName']?.toString().toLowerCase() ?? '';
        String fileUrl = file['url']?.toString() ?? '';

        if (fileName.endsWith('.png') ||
            fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.gif') ||
            fileName.endsWith('.bmp') ||
            fileName.endsWith('.webp')) {
          screenshotUrls.add(fileUrl);
        } else if (fileName.endsWith('.pdf') ||
            fileName.endsWith('.doc') ||
            fileName.endsWith('.docx') ||
            fileName.endsWith('.txt')) {
          documentUrls.add(fileUrl);
        }
      }

      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      // Ensure alert level is properly set
      final finalAlertLevel = alertLevel ?? widget.report.alertLevels;

      print('🔍 SUBMIT DEBUG - alertLevel variable: $alertLevel');
      print(
        '🔍 SUBMIT DEBUG - widget.report.alertLevels: ${widget.report.alertLevels}',
      );
      print('🔍 SUBMIT DEBUG - finalAlertLevel: $finalAlertLevel');
      print(
        '🔍 SUBMIT DEBUG - finalAlertLevel type: ${finalAlertLevel.runtimeType}',
      );
      print(
        '🔍 SUBMIT DEBUG - finalAlertLevel is null: ${finalAlertLevel == null}',
      );
      print(
        '🔍 SUBMIT DEBUG - finalAlertLevel is empty: ${finalAlertLevel?.isEmpty}',
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

      final updatedReport = widget.report
        ..alertLevels = finalAlertLevel
        ..screenshotPaths = screenshotUrls
        ..documentPaths = documentUrls;

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

      // 2. If online, send to backend and update local status
      if (isOnline) {
        try {
          print('Sending to backend: ${updatedReport.toJson()}');
          await ApiService().submitFraudReport(updatedReport.toJson());
          print('Backend response: submitted');
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
            screenshotPaths: updatedReport.screenshotPaths,
            documentPaths: updatedReport.documentPaths,
          );
          try {
            await FraudReportService.updateReport(clonedReport); // mark synced
          } catch (e) {
            print('Failed to mark as synced: $e');
          }
        } catch (e) {
          debugPrint('❌ Failed to sync now, will retry later: $e');
        }
      }

      // 3. Navigate to success page
      print('Navigating to success page...');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportSuccess(label: 'Scam Report'),
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
                reportType: 'fraud', // Specify fraud report type
                autoUpload: true,
                onFilesUploaded: (List<Map<String, dynamic>> uploadedFiles) {
                  // Handle uploaded files
                  print('Files uploaded: ${uploadedFiles.length}');
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
