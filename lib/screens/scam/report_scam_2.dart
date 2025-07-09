import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:security_alert/custom/CustomDropdown.dart';
import 'package:security_alert/custom/customButton.dart';
import '../../models/scam_report_model.dart';
import '../dashboard_page.dart';
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
  int screenshotCount = 0;
  final List<String> severityLevels = ['Low', 'Medium', 'High', 'Critical'];
  final ScamRemoteService _remoteService = ScamRemoteService();
  bool _isSubmitting = false;

  Future<void> _saveReport() async {
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final box = Hive.box<ScamReportModel>('scam_reports');
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;
      
      // Create a comprehensive description including all collected data
      String fullDescription = widget.description ?? '';
      String phone = widget.phone ?? '';
      String email = widget.email ?? '';
      String website = widget.website ?? '';

      // if (widget.phone != null && widget.phone!.isNotEmpty) {
      //   fullDescription += '\n\nPhone: ${widget.phone}';
      // }
      // if (widget.email != null && widget.email!.isNotEmpty) {
      //   fullDescription += '\nEmail: ${widget.email}';
      // }
      // if (widget.website != null && widget.website!.isNotEmpty) {
      //   fullDescription += '\nWebsite: ${widget.website}';
      // }
      
      final report = ScamReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${widget.scamType} Scam Report',
        email: email,
        phone: phone,
        website: website,
        description: fullDescription,
        type: widget.scamType,
        severity: severity ?? 'Medium',
        date: DateTime.now(),
        isSynced: false,
       // Start as false, will be updated after sync attempt
      );

      // Save to local storage first
      await box.add(report);


      // Try to sync with backend if online
      if (isOnline) {
        try {
          bool syncSuccess = await _remoteService.sendReport(report);
          if (syncSuccess) {
            // Update the report as synced
            final syncedReport = ScamReportModel(
              id: report.id,
              title: report.title,
              email: report.email,
              phone: report.phone,
              website: report.website,
              description: report.description,
              type: report.type,
              severity: report.severity,
              date: report.date,
              isSynced: true,

            );
            // Find and update the report in the box
            final reports = box.values.toList();
            for (int i = 0; i < reports.length; i++) {
              if (reports[i].id == report.id) {
                await box.putAt(i, syncedReport);
                break;
              }
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully and synced with server!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report saved locally. Will sync when connection is restored.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Report saved locally. Sync failed: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report saved locally. Will sync when connection is restored.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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


              CustomButton(
                text: _isSubmitting ? 'Submitting...' : 'Submit', 
                onPressed: _isSubmitting ? null : () async {
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
                fontWeight: FontWeight.normal
              )
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
