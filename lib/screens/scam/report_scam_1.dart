import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:security_alert/custom/CustomDropdown.dart';
import 'package:security_alert/custom/customButton.dart';
import 'package:security_alert/custom/customTextfield.dart';

import '../../models/scam_report_model.dart';
import 'report_scam_2.dart';
import 'view_pending_reports.dart';
import 'scam_report_service.dart';

class ReportScam1 extends StatefulWidget {
  const ReportScam1({Key? key}) : super(key: key);

  @override
  State<ReportScam1> createState() => _ReportScam1State();
}

class _ReportScam1State extends State<ReportScam1> {
  final _formKey = GlobalKey<FormState>();
  String? scamType, phone, email, website, description;
  bool _isOnline = true;

  final List<String> scamTypes = [
    'Phishing',
    'Lottery',
    'Investment',
    'Romance',
    'Tech Support',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initHive();
    _setupConnectivityListener();
  }

  Future<void> _initHive() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    await Hive.openBox<ScamReportModel>('scam_reports');
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        print('Internet connection restored, syncing reports...');
        ScamReportService.syncReports();
      }
    });
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
              CustomDropdown(label: 'Scam Type', hint: 'Select a Scam Type',
                items: scamTypes, value: scamType,
                onChanged: (val) => setState(() => scamType = val),),

              const SizedBox(height: 16),
              const Text(
                'Scammer details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CustomTextField(label: 'Phone*',hintText: '+91-979864483',
                onChanged:(val) => phone = val,
                keyboardType: TextInputType.phone,
                 ),
              // TextFormField(
              //   keyboardType: TextInputType.phone,
              //   decoration: const InputDecoration(
              //     labelText: 'Phone*',
              //     hintText: '+91-979864483',
              //     border: OutlineInputBorder(),
              //   ),
              //   onChanged: (val) => phone = val,
              //   validator: (val) =>
              //       val == null || val.isEmpty ? 'Required' : null,
              // ),
              const SizedBox(height: 12),
              CustomTextField(label: 'Email*',hintText: 'fathanah@gmail.com',
                onChanged:(val) => email = val,
                keyboardType: TextInputType.emailAddress,
               ),
              // TextFormField(
              //   keyboardType: TextInputType.emailAddress,
              //   decoration: const InputDecoration(
              //     labelText: 'Email*',
              //     hintText: 'fathanah@gmail.com',
              //     border: OutlineInputBorder(),
              //   ),
              //   onChanged: (val) => email = val,
              //   validator: (val) =>
              //       val == null || val.isEmpty ? 'Required' : null,
              // ),
              const SizedBox(height: 12),
              CustomTextField(label: 'Website',hintText: 'www.fathanah.com',
                onChanged:(val) => website = val,
                keyboardType: TextInputType.webSearch,
                ),
              // TextFormField(
              //   decoration: const InputDecoration(
              //     labelText: 'Website',
              //     hintText: 'www.fathanah.com',
              //     border: OutlineInputBorder(),
              //   ),
              //   onChanged: (val) => website = val,
              // ),
              const SizedBox(height: 12),
              CustomTextField(label: 'Description*',hintText: 'Describe the scam...',
                onChanged:(val) => description = val,
                keyboardType: TextInputType.text,
                ),
              // TextFormField(
              //   maxLines: 4,
              //   decoration: const InputDecoration(
              //     labelText: 'Description',
              //     hintText: 'Describe the scam...',
              //     border: OutlineInputBorder(),
              //   ),
              //   onChanged: (val) => description = val,
              // ),
              const SizedBox(height: 24),
              CustomButton(text: 'Next', onPressed: () async{
                if (_formKey.currentState!.validate()) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportScam2(
                        scamType: scamType ?? '',
                        phone: phone,
                        email: email,
                        website: website,
                        description: description,
                      ),
                    ),
                  );
                }
                return;
              },
                  fontWeight: FontWeight.normal),

            ],
          ),
        ),
      ),
    );
  }

  Future<void> submitMalwareReport(ScamReportModel report) async {
    // Use the centralized service to save and sync the report
    await ScamReportService.saveReport(report);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(report.isSynced 
            ? 'Report sent and saved as synced!' 
            : 'Report saved locally. Will sync when connection is restored.'),
          backgroundColor: report.isSynced ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
  