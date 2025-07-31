// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:hive/hive.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:security_alert/screens/scam/scam_report_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import '../../custom/attach.dart';
// import '../../services/jwt_service.dart';
//
// import '../../models/scam_report_model.dart';
//
// import '../../custom/customButton.dart';
// import '../../custom/customDropdown.dart';
// import '../../custom/Success_page.dart';
// import '../../services/api_service.dart';
// import '../../custom/fileUpload.dart';
//
// class ReportScam2 extends StatefulWidget {
//   final ScamReportModel report;
//   const ReportScam2({required this.report});
//
//   @override
//   State<ReportScam2> createState() => _ReportScam2State();
// }
//
// class _ReportScam2State extends State<ReportScam2> {
//   final _formKey = GlobalKey<FormState>();
//   String? alertLevel;
//   List<File> screenshots = [], documents = [], voiceMessages = [];
//   final List<String> alertLevels = ['Low', 'Medium', 'High', 'Critical'];
//   final ImagePicker picker = ImagePicker();
//   bool isUploading = false;
//   String uploadStatus = '';
//   final GlobalKey<FileUploadWidgetState> _fileUploadKey =
//       GlobalKey<FileUploadWidgetState>(debugLabel: 'scam_file_upload');
//
//   // Track uploaded files response data
//   Map<String, dynamic>? uploadedFilesData;
//   bool filesUploaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize alert level with current value from report
//     alertLevel = widget.report.alertLevels;
//
//
//     // If no alert level is set, we'll capture it from user selection
//     if (alertLevel == null || alertLevel!.isEmpty) {
//
//     }
//   }
//
//
//
//   Future<void> _submitFinalReport() async {
//
//     // Validate alert level selection
//     if (alertLevel == null || alertLevel!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please select an alert severity level'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     setState(() {
//       isUploading = true;
//       uploadStatus = 'Preparing files for upload...';
//     });
//
//     try {
//       // ALWAYS upload files first before submitting the report
//       Map<String, dynamic> uploadedFiles = {};
//
//
//
//       if (_fileUploadKey.currentState != null) {
//         // Check if files are selected
//         final state = _fileUploadKey.currentState!;
//         print('📤 Files selected: ${state.selectedImages.length} images, ${state.selectedDocuments.length} documents, ${state.selectedVoiceFiles.length} voice files');
//
//         if (state.selectedImages.isEmpty &&
//             state.selectedDocuments.isEmpty &&
//             state.selectedVoiceFiles.isEmpty) {
//           uploadedFiles = {
//             'screenshots': [],
//             'voiceMessages': [],
//             'documents': [],
//           };
//         } else {
//           // Force upload files
//           uploadedFiles = await _fileUploadKey.currentState!.triggerUpload();
//
//           // Store uploaded files for future use
//           setState(() {
//             uploadedFilesData = uploadedFiles;
//             filesUploaded = true;
//           });
//         }
//       } else {
//         print('❌ FileUploadWidget not found!');
//         uploadedFiles = {
//           'screenshots': [],
//           'voiceMessages': [],
//           'documents': [],
//         };
//       }
//
//       // Debug: Check if files were actually uploaded
//       final uploadedScreenshots = uploadedFiles['screenshots'] as List? ?? [];
//       final uploadedDocuments = uploadedFiles['documents'] as List? ?? [];
//       final uploadedVoiceMessages = uploadedFiles['voiceMessages'] as List? ?? [];
//
//       if (uploadedScreenshots.isEmpty && uploadedDocuments.isEmpty && uploadedVoiceMessages.isEmpty) {
//         // Show warning to user but continue with submission
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('No files uploaded. Report will be submitted without attachments.'),
//             backgroundColor: Colors.orange,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//
//       // Extract URLs from categorized files for backward compatibility
//       List<String> screenshotUrls = [];
//       List<String> documentUrls = [];
//       List<String> voiceMessageUrls = [];
//
//       for (var file in uploadedScreenshots) {
//         String fileUrl = file['url']?.toString() ?? '';
//         if (fileUrl.isNotEmpty) {
//           screenshotUrls.add(fileUrl);
//         }
//       }
//
//       for (var file in uploadedDocuments) {
//         String fileUrl = file['url']?.toString() ?? '';
//         if (fileUrl.isNotEmpty) {
//           documentUrls.add(fileUrl);
//         }
//       }
//
//       for (var file in uploadedVoiceMessages) {
//         String fileUrl = file['url']?.toString() ?? '';
//         if (fileUrl.isNotEmpty) {
//           voiceMessageUrls.add(fileUrl);
//         }
//       }
//
//       final connectivity = await Connectivity().checkConnectivity();
//       final isOnline = connectivity != ConnectivityResult.none;
//
//       // Ensure alert level is properly set
//       final finalAlertLevel = alertLevel ?? widget.report.alertLevels;
//    // Validate that we have a proper alert level
//       if (finalAlertLevel == null || finalAlertLevel.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Please select an alert severity level'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//
//       // Create complete report data with files for backend
//       final formData = {
//         'reportCategoryId': widget.report.reportCategoryId,
//         'reportTypeId': widget.report.reportTypeId,
//         'alertLevels': finalAlertLevel,
//         'keycloackUserId': widget.report.keycloakUserId,
//         'userId': widget.report.keycloakUserId, // Add userId field
//         'phoneNumber': widget.report.phoneNumber,
//         'email': widget.report.email,
//         'website': widget.report.website,
//         'description': widget.report.description,
//         'name': widget.report.name ?? 'Anonymous',
//         'createdBy': widget.report.keycloakUserId, // Add createdBy field
//         'isActive': true,
//       };
//
//       // Create complete report data with file objects for backend
//       final completeReportData = FileUploadService.createReportData(
//         formData: formData,
//         fileData: uploadedFiles,
//       );
//    // Debug: Show example file objects
//       if ((completeReportData['screenshots'] as List).isNotEmpty) {
//
//       }
//       if ((completeReportData['voiceMessages'] as List).isNotEmpty) {
//
//       }
//       if ((completeReportData['documents'] as List).isNotEmpty) {
//
//       }
//
//
//       final requiredFields = [
//         'reportCategoryId', 'reportTypeId', 'alertLevels', 'keycloackUserId',
//         'userId', 'phoneNumber', 'email', 'website', 'description', 'name', 'createdBy'
//       ];
//
//       for (String field in requiredFields) {
//         if (!completeReportData.containsKey(field) || completeReportData[field] == null) {
//           print('❌ Missing required field: $field');
//         } else {
//           print('✅ Field present: $field = ${completeReportData[field]}');
//         }
//       }
//
//       // Validate file arrays
//       final fileArrays = ['screenshots', 'voiceMessages', 'documents'];
//       for (String array in fileArrays) {
//         if (completeReportData.containsKey(array)) {
//           final files = completeReportData[array] as List;
//           print('✅ $array: ${files.length} files');
//           if (files.isNotEmpty) {
//             print('  Example file structure: ${files[0]}');
//           }
//         } else {
//           print('❌ Missing file array: $array');
//         }
//       }
//
//       // Update local report model for backward compatibility
//       final updatedReport = widget.report
//         ..alertLevels = finalAlertLevel
//         ..screenshots = screenshotUrls
//         ..documents = documentUrls
//         ..voiceMessages = voiceMessageUrls;
//
//  // 1. Save locally (Always)
//       final box = Hive.box<ScamReportModel>('scam_reports');
//       if (updatedReport.isInBox) {
//         // If already in box, update by key
//         await ScamReportService.updateReport(updatedReport);
//       } else {
//         // If not in box, add as new
//         await ScamReportService.saveReportOffline(updatedReport);
//       }
//
//       // 2. If online, send to backend with complete file objects
//       if (isOnline) {
//         try {
//
//           final expectedStructure = {
//             'reportCategoryId': 'string',
//             'reportTypeId': 'string',
//             'alertLevels': 'string',
//             'keycloackUserId': 'string',
//             'userId': 'string',
//             'phoneNumber': 'number',
//             'email': 'string',
//             'website': 'string',
//             'description': 'string',
//             'name': 'string',
//             'createdBy': 'string',
//             'screenshots': 'array',
//             'voiceMessages': 'array',
//             'documents': 'array'
//           };
//
//           for (String key in expectedStructure.keys) {
//             if (!completeReportData.containsKey(key)) {
//               print('❌ Missing expected field: $key');
//             } else {
//               final value = completeReportData[key];
//               final expectedType = expectedStructure[key];
//               print('✅ Field present: $key = $value (${value.runtimeType})');
//             }
//           }
//
//           // Send the complete report data with file objects to backend
//           // This should include screenshots, voiceMessages, and documents arrays
//           await ApiService().submitScamReport(completeReportData);
//
//           print('✅ Backend response: submitted successfully with files');
//           print('✅ Files sent to backend:');
//           print('  📸 Screenshots: ${(completeReportData['screenshots'] as List).length}');
//           print('  🎵 Voice Messages: ${(completeReportData['voiceMessages'] as List).length}');
//           print('  📄 Documents: ${(completeReportData['documents'] as List).length}');
//
//           updatedReport.isSynced = true;
//
//           // Clone the object before updating to avoid HiveError
//           final clonedReport = ScamReportModel(
//             id: updatedReport.id,
//             keycloakUserId: updatedReport.keycloakUserId,
//             reportCategoryId: updatedReport.reportCategoryId,
//             reportTypeId: updatedReport.reportTypeId,
//             alertLevels: updatedReport.alertLevels,
//             phoneNumber: updatedReport.phoneNumber,
//             email: updatedReport.email,
//             website: updatedReport.website,
//             description: updatedReport.description,
//             createdAt: updatedReport.createdAt,
//             updatedAt: DateTime.now(),
//             isSynced: true,
//           );
//           await ScamReportService.updateReport(clonedReport); // mark synced
//         } catch (e) {
//           debugPrint('❌ Failed to sync now, will retry later: $e');
//           print('❌ Error details: $e');
//         }
//       }
//
//       setState(() {
//         isUploading = false;
//         uploadStatus = '';
//       });
//
//       // 3. Navigate to success page
//       print('Navigating to success page...');
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
//             content: Text('Scam Successfully Reported'),
//             duration: Duration(seconds: 2),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e, stack) {
//       print('Error in _submitFinalReport: $e\n$stack');
//       setState(() {
//         isUploading = false;
//         uploadStatus = '';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting report: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//
//
//   // Method to ensure files are selected and uploaded
//   Future<void> _ensureFilesSelected() async {
//     print('🔧 ENSURING FILES SELECTED - Starting...');
//
//     if (_fileUploadKey.currentState != null) {
//       final state = _fileUploadKey.currentState!;
//
//       if (state.selectedImages.isEmpty &&
//           state.selectedDocuments.isEmpty &&
//           state.selectedVoiceFiles.isEmpty) {
//         print('🔧 ENSURING FILES SELECTED - No files selected, prompting user...');
//
//         // Show dialog to prompt user to select files
//         bool? shouldSelectFiles = await showDialog<bool>(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: Text('No Files Selected'),
//               content: Text('Would you like to select files before submitting the report?'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(false),
//                   child: Text('Submit Without Files'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(true),
//                   child: Text('Select Files'),
//                 ),
//               ],
//             );
//           },
//         );
//
//         if (shouldSelectFiles == true) {
//           // Open file picker
//           try {
//             // Select images
//             final images = await ImagePicker().pickMultiImage();
//             if (images != null) {
//               setState(() {
//                 state.selectedImages.addAll(images.map((e) => File(e.path)));
//               });
//               print('🔧 ENSURING FILES SELECTED - Added ${images.length} images');
//             }
//
//             // Select documents
//             final documents = await FilePicker.platform.pickFiles(
//               allowMultiple: true,
//               type: FileType.custom,
//               allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
//             );
//             if (documents != null) {
//               setState(() {
//                 state.selectedDocuments.addAll(documents.paths.map((e) => File(e!)));
//               });
//               print('🔧 ENSURING FILES SELECTED - Added ${documents.files.length} documents');
//             }
//
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Files selected: ${state.selectedImages.length} images, ${state.selectedDocuments.length} documents'),
//                 backgroundColor: Colors.green,
//               ),
//             );
//           } catch (e) {
//             print('🔧 ENSURING FILES SELECTED - Error selecting files: $e');
//           }
//         }
//       } else {
//         print('🔧 ENSURING FILES SELECTED - Files already selected');
//       }
//     }
//   }
//
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
//
//               FileUploadWidget(
//                 key: _fileUploadKey,
//                 reportId: widget.report.id ?? '123',
//                 fileType: 'scam', // Specify scam report type
//                 autoUpload: false,
//                 onFilesUploaded: (Map<String, dynamic> uploadedFiles) {
//                   // Handle uploaded files
//                   final screenshots = uploadedFiles['screenshots'] as List? ?? [];
//                   final documents = uploadedFiles['documents'] as List? ?? [];
//                   final voiceMessages = uploadedFiles['voiceMessages'] as List? ?? [];
//
//                   // Debug: Show uploaded files data
//
//
//                   // Store uploaded files response data for submission
//                   setState(() {
//                     uploadedFilesData = uploadedFiles;
//                     filesUploaded = true;
//                   });
//
//                   // Show success message
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Files uploaded successfully!'),
//                       backgroundColor: Colors.green,
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 },
//               ),
//
//               // Manual upload button
//               SizedBox(height: 16),
//
//               if (uploadedFilesData != null && filesUploaded) ...[
//                 SizedBox(height: 16),
//
//               ],
//               // AttachmentUploadWidget(),
//               const SizedBox(height: 20),
//
//               CustomDropdown(
//                 label: 'Alert Severity *',
//                 hint: 'Select severity (Required)',
//                 items: alertLevels,
//                 value: alertLevel,
//                 onChanged: (val) {
//                   setState(() => alertLevel = val);
//                 },
//               ),
//               const SizedBox(height: 10),
//               // Debug button to test alert level
//               if (alertLevel != null)
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     border: Border.all(color: Colors.blue.shade200),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     'Selected Alert Level: $alertLevel',
//                     style: TextStyle(
//                       color: Colors.blue.shade700,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               const SizedBox(height: 20),
//
//
//
//
//
//
//               const SizedBox(height: 10),
//
//               // Upload status
//               if (uploadStatus.isNotEmpty)
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   margin: const EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     border: Border.all(color: Colors.blue.shade200),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       if (isUploading)
//                         const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           uploadStatus,
//                           style: TextStyle(
//                             color: Colors.blue.shade700,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//               const SizedBox(height: 40),
//               // Show warning if no files uploaded
//               if (!filesUploaded && uploadedFilesData == null) ...[
//                 Container(
//                   padding: EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade50,
//                     border: Border.all(color: Colors.orange.shade200),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
//                       SizedBox(width: 8),
//                       // Expanded(
//                       //   child: Text(
//                       //     'No files uploaded. Report will be submitted without attachments.',
//                       //     style: TextStyle(
//                       //       color: Colors.orange.shade700,
//                       //       fontSize: 14,
//                       //     ),
//                       //   ),
//                       // ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 16),
//               ],
//               CustomButton(
//                 text: isUploading ? 'Uploading...' : 'Submit',
//                 onPressed: isUploading ? null : () async {
//                   // First ensure files are selected
//                   await _ensureFilesSelected();
//                   // Then submit the report
//                   await _submitFinalReport();
//                 },
//                 fontWeight: FontWeight.normal,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:security_alert/screens/scam/scam_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../custom/attach.dart';
import '../../services/jwt_service.dart';
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
  final List<String> alertLevels = ['Low', 'Medium', 'High', 'Critical'];
  bool isUploading = false;
  String uploadStatus = '';
  Map<String, dynamic>? uploadedFilesData;
  bool filesUploaded = false;

  final GlobalKey<FileUploadWidgetState> _fileUploadKey =
  GlobalKey<FileUploadWidgetState>(debugLabel: 'scam_file_upload');

  @override
  void initState() {
    super.initState();
    alertLevel = widget.report.alertLevels;
  }

  Future<void> _submitFinalReport() async {
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
      uploadStatus = 'Preparing files for upload...';
    });

    try {
      Map<String, dynamic> uploadedFiles = {
        'screenshots': [],
        'documents': [],
        'voiceMessages': [],
      };

      if (_fileUploadKey.currentState != null) {
        final state = _fileUploadKey.currentState!;
        if (state.selectedImages.isNotEmpty ||
            state.selectedDocuments.isNotEmpty ||
            state.selectedVoiceFiles.isNotEmpty) {
          uploadedFiles = await state.triggerUpload();
          setState(() {
            uploadedFilesData = uploadedFiles;
            filesUploaded = true;
          });
        }
      }

      final screenshotUrls = (uploadedFiles['screenshots'] as List)
          .map((f) => f['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final documentUrls = (uploadedFiles['documents'] as List)
          .map((f) => f['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final voiceMessageUrls = (uploadedFiles['voiceMessages'] as List)
          .map((f) => f['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      final formData = {
        'reportCategoryId': widget.report.reportCategoryId,
        'reportTypeId': widget.report.reportTypeId,
        'alertLevels': alertLevel!,
        'keycloackUserId': widget.report.keycloakUserId,
        'userId': widget.report.keycloakUserId,
        'phoneNumber': widget.report.phoneNumber,
        'email': widget.report.email,
        'website': widget.report.website,
        'description': widget.report.description,
        'name': widget.report.name ?? 'Anonymous',
        'createdBy': widget.report.keycloakUserId,
        'isActive': true,
        'screenshots': uploadedFiles['screenshots'],
        'documents': uploadedFiles['documents'],
        'voiceMessages': uploadedFiles['voiceMessages'],
      };

      final updatedReport = widget.report
        ..alertLevels = alertLevel
        ..screenshots = screenshotUrls
        ..documents = documentUrls
        ..voiceMessages = voiceMessageUrls;

      final box = Hive.box<ScamReportModel>('scam_reports');
      if (updatedReport.isInBox) {
        await ScamReportService.updateReport(updatedReport);
      } else {
        await ScamReportService.saveReportOffline(updatedReport);
      }

      if (isOnline) {
        try {
          await ApiService().submitScamReport(formData);

          final clonedReport = ScamReportModel(
            id: updatedReport.id,
            keycloakUserId: updatedReport.keycloakUserId,
            reportCategoryId: updatedReport.reportCategoryId,
            reportTypeId: updatedReport.reportTypeId,
            alertLevels: updatedReport.alertLevels,
            phoneNumber: updatedReport.phoneNumber,
            email: updatedReport.email,
            website: updatedReport.website,
            description: updatedReport.description,
            createdAt: updatedReport.createdAt,
            updatedAt: DateTime.now(),
            isSynced: true,
          );
          await ScamReportService.updateReport(clonedReport);
        } catch (e) {
          print('❌ Error syncing with backend: $e');
        }
      }

      setState(() {
        isUploading = false;
        uploadStatus = '';
      });

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
            content: Text('Scam Successfully Reported'),
            duration: Duration(seconds: 2),
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
        ),
      );
    }
  }

  Future<void> _ensureFilesSelected() async {
    if (_fileUploadKey.currentState != null) {
      final state = _fileUploadKey.currentState!;

      if (state.selectedImages.isEmpty &&
          state.selectedDocuments.isEmpty &&
          state.selectedVoiceFiles.isEmpty) {
        final shouldSelectFiles = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('No Files Selected'),
            content:
            Text('Would you like to select files before submitting the report?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Submit Without Files'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Select Files'),
              ),
            ],
          ),
        );

        if (shouldSelectFiles == true) {
          try {
            final images = await ImagePicker().pickMultiImage();
            if (images != null) {
              setState(() {
                state.selectedImages.addAll(images.map((e) => File(e.path)));
              });
            }

            final documents = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.custom,
              allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
            );

            if (documents != null) {
              setState(() {
                state.selectedDocuments.addAll(documents.paths
                    .whereType<String>()
                    .map((path) => File(path)));
              });
            }
          } catch (e) {
            print('❌ Error selecting files: $e');
          }
        }
      }
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
                reportId: widget.report.id ?? '123',
                fileType: 'scam',
                autoUpload: false,
                onFilesUploaded: (files) {
                  setState(() {
                    uploadedFilesData = files;
                    filesUploaded = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Files uploaded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                label: 'Alert Severity *',
                hint: 'Select severity (Required)',
                items: alertLevels,
                value: alertLevel,
                onChanged: (val) => setState(() => alertLevel = val),
              ),
              const SizedBox(height: 10),
              if (uploadStatus.isNotEmpty) ...[
                Text(uploadStatus),
                const SizedBox(height: 10),
              ],
              CustomButton(
                text: isUploading ? 'Uploading...' : 'Submit Scam Report',
                onPressed: isUploading
                    ? null
                    : () async {
                  await _ensureFilesSelected();
                  await _submitFinalReport();
                },  fontWeight: FontWeight.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
