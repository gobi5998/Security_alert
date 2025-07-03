// malware_report_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../custom/CustomDropdown.dart';
import '../../custom/Success_page.dart';



class ScamReportPage2 extends StatefulWidget {
  const ScamReportPage2({super.key, required String phone, required String email, required String description, required String website, String? scamType});

  @override
  State<ScamReportPage2> createState() => _ScamReportPage2State();
}

class _ScamReportPage2State extends State<ScamReportPage2> {
  PlatformFile? selectedFile;
  final _formKey = GlobalKey<FormState>();

  // final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _systemAffectedController = TextEditingController();
  String? _selectedSeverity;

  void pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'zip'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size exceeds 10MB')),
        );
        return;
      }
      setState(() {
        selectedFile = file;
      });
    }
  }

  // void handleSubmit() {
  //   if (_formKey.currentState!.validate()) {
  //     if (selectedFile == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Please upload a file")),
  //       );
  //       return;
  //     }
  //
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => const SuccessDialog(
  //         title: 'Scam Report',
  //         message: 'Successfully Submitted',
  //       ),
  //     );
  //
  //     Future.delayed(const Duration(seconds: 2), () {
  //       Navigator.pop(context); // Close dialog
  //       setState(() {
  //         selectedFile = null;
  //         _nameController.clear();
  //         _systemAffectedController.clear();
  //         _selectedSeverity = null;
  //       });
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Scam')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Upload infected files", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListTile(
                        onTap: pickFile,
                        leading: const Icon(Icons.add),
                        title: const Text("Add Screenshots\nlimit: 0/5"),
                      ),
                      ListTile(
                        onTap: pickFile,
                        leading: const Icon(Icons.mic),
                        title: const Text("Add Voice Message\nLimit: 5mb"),
                      ),
                      ListTile(
                        onTap: pickFile,
                        leading: const Icon(Icons.file_copy),
                        title: const Text("Add Documents\nLimit: 5mb"),
                      ),
                      if (selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Selected: ${selectedFile!.name}",
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => selectedFile = null),
                              )
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Dropdown
                      CustomDropdown(
                        label: "Alert Severity Levels",
                        hint: "Select a Scam Type",
                        value: _selectedSeverity,
                        items: const ['High', 'Medium', 'Low'],
                        onChanged: (val) => setState(() => _selectedSeverity = val),
                      ),


                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportSuccess(label: 'Scam Report'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064FAD),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Submit", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}
