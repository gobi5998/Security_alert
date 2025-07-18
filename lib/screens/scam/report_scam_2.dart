import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:security_alert/screens/scam/scam_report_service.dart';

import '../../models/scam_report_model.dart';

import '../../custom/customButton.dart';
import '../../custom/customDropdown.dart';
import '../../custom/Success_page.dart';
import '../../services/api_service.dart';

class ReportScam2 extends StatefulWidget {
  final ScamReportModel report;
  const ReportScam2({required this.report});

  @override
  State<ReportScam2> createState() => _ReportScam2State();
}

class _ReportScam2State extends State<ReportScam2> {
  final _formKey = GlobalKey<FormState>();
  String? alertLevel;
  List<File> screenshots = [], documents = [], voices = [];
  final List<String> alertLevels = ['Low', 'Medium', 'High', 'Critical'];
  final ImagePicker picker = ImagePicker();

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
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ReportSuccess(label: 'Scam Report'),
        ),
        (route) => false,
      );
    }
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      final updatedReport = widget.report..alertLevels = alertLevel ?? '';

      // 1. Save locally (Always)
      await ScamReportService.saveReportOffline(updatedReport);

      // 2. If online, send to backend and update local status
      if (isOnline) {
        try {
          print('Sending to backend: ${updatedReport.toJson()}');
          await ApiService().submitScamReport(updatedReport.toJson());
          print('Backend response: submitted');
          // Update the synced status without creating a new object
          updatedReport.isSynced = true;
          await ScamReportService.updateReport(updatedReport);
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
                children: [
                  ListTile(
                    leading: Image.asset('assets/image/document.png'),
                    title: const Text('Add Screenshots'),
                    subtitle: Text('Selected: /5'),
                    // onTap: _pickScreenshots,
                  ),
                ],
              ),

              // Display selected screenshots
              // if (selectedScreenshots.isNotEmpty) ...[
              //   const SizedBox(height: 8),
              //   Container(
              //     height: 100,
              //     child: ListView.builder(
              //       scrollDirection: Axis.horizontal,
              //       // itemCount: selectedScreenshots.length,
              //       itemBuilder: (context, index) {
              //         return Padding(
              //           padding: const EdgeInsets.only(right: 8),
              //           child: Stack(
              //             children: [
              //               Container(
              //                 width: 100,
              //                 height: 100,
              //                 decoration: BoxDecoration(
              //                   borderRadius: BorderRadius.circular(8),
              //                   border: Border.all(color: Colors.grey),
              //                 ),
              //                 child: ClipRRect(
              //                   borderRadius: BorderRadius.circular(8),
              //                   child: Image.file(
              //                     selectedScreenshots[index],
              //                     fit: BoxFit.cover,
              //                   ),
              //                 ),
              //               ),
              //               Positioned(
              //                 top: 4,
              //                 right: 4,
              //                 child: GestureDetector(
              //                   onTap: () => _removeScreenshot(index),
              //                   child: Container(
              //                     padding: const EdgeInsets.all(2),
              //                     decoration: const BoxDecoration(
              //                       color: Colors.red,
              //                       shape: BoxShape.circle,
              //                     ),
              //                     child: const Icon(
              //                       Icons.close,
              //                       color: Colors.white,
              //                       size: 16,
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ],
              const SizedBox(height: 16),

              // Documents Section
              Column(
                children: [
                  ListTile(
                    leading: Image.asset('assets/image/document.png'),
                    title: const Text('Add Documents'),
                    subtitle: Text('Selected:  files'),
                    // onTap: _pickDocuments,
                  ),
                ],
              ),

              // Display selected documents
              // if (selectedDocuments.isNotEmpty) ...[
              //   const SizedBox(height: 8),
              //   ...selectedDocuments.asMap().entries.map((entry) {
              //     int index = entry.key;
              //     File file = entry.value;
              //     return Card(
              //       child: ListTile(
              //         leading: const Icon(Icons.description),
              //         title: Text(file.path.split('/').last),
              //         subtitle: Text(
              //           '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
              //         ),
              //         trailing: IconButton(
              //           icon: const Icon(Icons.close, color: Colors.red),
              //           onPressed: () => _removeDocument(index),
              //         ),
              //       ),
              //     );
              //   }).toList(),
              // ],
              CustomDropdown(
                label: 'Alert Severity',
                hint: 'Select severity',
                items: alertLevels,
                value: alertLevel,
                onChanged: (val) => setState(() => alertLevel = val),
              ),
              const SizedBox(height: 20),
              // ListTile(
              //   leading: const Icon(Icons.image),
              //   title: const Text('Add Screenshots'),
              //   subtitle: Text('${screenshots.length} selected'),
              //   onTap: () => _pickFiles('screenshot'),
              // ),
              // ListTile(
              //   leading: const Icon(Icons.insert_drive_file),
              //   title: const Text('Add Documents'),
              //   subtitle: Text('${documents.length} selected'),
              //   onTap: () => _pickFiles('document'),
              // ),
              // ListTile(
              //   leading: const Icon(Icons.mic),
              //   title: const Text('Add Voice Notes'),
              //   subtitle: Text('${voices.length} selected'),
              //   onTap: () => _pickFiles('voice'),
              // ),
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
