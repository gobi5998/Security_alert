import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:security_alert/custom/CustomDropdown.dart';
import 'package:security_alert/custom/customButton.dart';
import '../../models/scam_report_model.dart';
import '../dashboard_page.dart';

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
  int screenshotCount = 0;
  final List<String> severityLevels = ['Low', 'Medium', 'High', 'Critical'];

  Future<void> _saveReport() async {
    final box = Hive.box<ScamReportModel>('scam_reports');
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    final report = ScamReportModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.scamType,
      description: widget.description ?? '',
      type: widget.scamType,
      severity: severity ?? 'Medium',
      date: DateTime.now(),
      isSynced: isOnline,
    );
    await box.add(report);
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
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Screenshots'),
                subtitle: Text('limit: $screenshotCount/5'),
                onTap: () {
                  setState(() {
                    if (screenshotCount < 5) screenshotCount++;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Voice Message'),
                subtitle: const Text('limit: 5mb'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Documents'),
                subtitle: const Text('limit: 5mb'),
                onTap: () {},
              ),
              const SizedBox(height: 16),

              CustomDropdown(label: 'Alert Severity Levels', hint: 'Select a Severity Level', items: severityLevels, value: severity, onChanged: (val) => setState(() => severity = val,),),
               SizedBox(height: 24),

              CustomButton(text: 'Submit', onPressed: () async {
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
              }, fontWeight: FontWeight.normal)
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: const Color(0xFF064FAD),
              //       minimumSize: const Size(double.infinity, 48),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     onPressed: () async {
              //       if (_formKey.currentState!.validate()) {
              //         await _saveReport();
              //         if (!mounted) return;
              //         Navigator.pushAndRemoveUntil(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => const DashboardPage(),
              //           ),
              //           (route) => false,
              //         );
              //       }
              //     },
              //     child: const Text('Submit'),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
