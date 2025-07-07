import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/scam_report_model.dart';
import '../screens/dashboard_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'scam_remote_service.dart';

class ReportScam2 extends StatefulWidget {
  final String scamType;
  final String? phone, email, website, description;
  const ReportScam2({
    Key? key,
    required this.scamType,
    this.phone,
    this.email,
    this.website,
    this.description,
  }) : super(key: key);

  @override
  State<ReportScam2> createState() => _ReportScam2State();
}

class _ReportScam2State extends State<ReportScam2> {
  final _formKey = GlobalKey<FormState>();
  String? severity;
  List<File> selectedScreenshots = [];
  List<File> selectedDocuments = [];
  final List<String> severityLevels = ['Low', 'Medium', 'High', 'Critical'];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickScreenshots() async {
    try {
      // Show dialog to choose between camera and gallery
      final choice = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Screenshots'),
            content: const Text('Choose how you want to add screenshots'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('camera'),
                child: const Text('Camera'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('gallery'),
                child: const Text('Gallery'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (choice == null) return;

      List<XFile> images = [];

      if (choice == 'camera') {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null) {
          images.add(image);
        }
      } else if (choice == 'gallery') {
        images = await _imagePicker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      }

      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if (selectedScreenshots.length < 5) {
              selectedScreenshots.add(File(image.path));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maximum 5 screenshots allowed')),
              );
              break;
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  Future<void> _pickDocuments() async {
    try {
      // Show dialog to choose file type
      final choice = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Documents'),
            content: const Text('Choose the type of documents to upload'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('all'),
                child: const Text('All Files'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('images'),
                child: const Text('Images Only'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('documents'),
                child: const Text('Documents Only'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (choice == null) return;

      List<String> allowedExtensions = [];
      String dialogTitle = '';

      switch (choice) {
        case 'all':
          allowedExtensions = [
            'pdf',
            'doc',
            'docx',
            'txt',
            'jpg',
            'jpeg',
            'png',
            'gif',
          ];
          dialogTitle = 'Select Files';
          break;
        case 'images':
          allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
          dialogTitle = 'Select Images';
          break;
        case 'documents':
          allowedExtensions = ['pdf', 'doc', 'docx', 'txt'];
          dialogTitle = 'Select Documents';
          break;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              selectedDocuments.add(File(file.path!));
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${result.files.length} file(s)')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking documents: $e')));
    }
  }

  void _removeScreenshot(int index) {
    setState(() {
      selectedScreenshots.removeAt(index);
    });
  }

  void _removeDocument(int index) {
    setState(() {
      selectedDocuments.removeAt(index);
    });
  }

  Future<void> _saveReport() async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    // Create the report
    final report = ScamReportModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.scamType,
      description: widget.description ?? '',
      type: widget.scamType,
      severity: severity ?? 'Medium',
      date: DateTime.now(),
      phone: widget.phone,
      email: widget.email,
      website: widget.website,
      isSynced: false, // Always start as not synced
      screenshotPaths: selectedScreenshots.map((file) => file.path).toList(),
      documentPaths: selectedDocuments.map((file) => file.path).toList(),
    );

    // Debug: Print file paths
    print('📁 Screenshot paths: ${report.screenshotPaths}');
    print('📁 Document paths: ${report.documentPaths}');

    // Save locally first
    await box.add(report);

    // If online, try to sync immediately
    if (isOnline) {
      try {
        final remoteService = ScamRemoteService();
        final success = await remoteService.sendReport(report);
        if (success) {
          // Update the report as synced
          report.isSynced = true;
          await box.put(report.id, report);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report submitted and synced successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Report saved locally. Will sync when connection is restored.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report saved locally. Sync failed: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      // Offline - just save locally
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report saved locally. Will sync when online.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Scam'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Upload evidence:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Screenshots Section
              Card(
                child: ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Add Screenshots'),
                  subtitle: Text('Selected: ${selectedScreenshots.length}/5'),
                  onTap: _pickScreenshots,
                ),
              ),

              // Display selected screenshots
              if (selectedScreenshots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedScreenshots.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedScreenshots[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeScreenshot(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Documents Section
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: const Text('Add Documents'),
                  subtitle: Text('Selected: ${selectedDocuments.length} files'),
                  onTap: _pickDocuments,
                ),
              ),

              // Display selected documents
              if (selectedDocuments.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...selectedDocuments.asMap().entries.map((entry) {
                  int index = entry.key;
                  File file = entry.value;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(file.path.split('/').last),
                      subtitle: Text(
                        '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeDocument(index),
                      ),
                    ),
                  );
                }).toList(),
              ],

              const SizedBox(height: 16),
              const Text(
                'Alert Severity Levels',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: severity,
                hint: const Text('Select a Severity Level'),
                items: severityLevels
                    .map(
                      (level) =>
                          DropdownMenuItem(value: level, child: Text(level)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => severity = val),
                validator: (val) => val == null ? 'Required' : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064FAD),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _saveReport();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardPage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
