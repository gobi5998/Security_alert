import 'package:flutter/material.dart';
import '../scam/malware_report_success.dart';

class Report_spam_2 extends StatefulWidget {
  final String malwareType;
  final String deviceType;
  final String? os;
  final String? detectionMethod;
  final String? location;
  const Report_spam_2({
    Key? key,
    required this.malwareType,
    required this.deviceType,
    this.os,
    this.detectionMethod,
    this.location,
  }) : super(key: key);

  @override
  State<Report_spam_2> createState() => _Report_spam_2State();
}

class _Report_spam_2State extends State<Report_spam_2> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? systemAffected;
  String? severity;
  // For simplicity, file upload is just a placeholder
  String? fileName;

  final List<String> severityLevels = ['Low', 'Medium', 'High', 'Critical'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Spam'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload infected files'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // File picker logic placeholder
                  setState(() {
                    fileName = 'infected_file.zip';
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        fileName ?? 'Upload Files\nLimit: 10mb',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Report spam attack details'),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Name'),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(hintText: 'System Affected'),
                onChanged: (val) => systemAffected = val,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: severity,
                hint: const Text('Select a Scam Type'),
                items: severityLevels
                    .map(
                      (level) =>
                          DropdownMenuItem(value: level, child: Text(level)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => severity = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MalwareReportSuccess(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064FAD),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
