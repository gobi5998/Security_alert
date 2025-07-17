import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:security_alert/custom/CustomDropdown.dart';
import 'package:security_alert/custom/customButton.dart';
import 'package:security_alert/custom/customTextfield.dart';
import 'package:security_alert/custom/customValidator.dart';
import '../../models/fraud_report_model.dart';
import '../Fraud/Fraud_report_service.dart';
import 'ReportFraudStep2.dart';


class ReportFraudStep1 extends StatefulWidget {
  const ReportFraudStep1({Key? key}) : super(key: key);

  @override
  State<ReportFraudStep1> createState() => _ReportFraudStep1State();
}

class _ReportFraudStep1State extends State<ReportFraudStep1> {
  final _formKey = GlobalKey<FormState>();
  String? fraudType,name,phone, email, website;
  bool _isOnline = true;

  final List<String> fraudTypes = [
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
    await Hive.openBox<FraudReportModel>('Fraud_reports');
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        print('Internet connection restored, syncing reports...');
        FraudReportService.syncReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Fraud'),
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
              CustomDropdown(label: 'Fraud Type', hint: 'Select a Fraud Type',
                items: fraudTypes, value: fraudType,
                onChanged: (val) => setState(() => fraudType = val),),

              const SizedBox(height: 16),
              const Text(
                'Fraudmer details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CustomTextField(label: 'Name*',hintText: 'John deo',
                onChanged:(val) => name = val,
                keyboardType: TextInputType.phone,
                validator: validatePhone,
              ),

              const SizedBox(height: 8),
              CustomTextField(label: 'Phone*',hintText: '+91-979864483',
                onChanged:(val) => phone = val,
                keyboardType: TextInputType.phone,
                validator: validatePhone,
              ),

              const SizedBox(height: 12),
              CustomTextField(label: 'Email*',hintText: 'fathanah@gmail.com',
                onChanged:(val) => email = val,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),

              const SizedBox(height: 12),
              CustomTextField(label: 'Website',hintText: 'www.fathanah.com',
                onChanged:(val) => website = val,
                keyboardType: TextInputType.webSearch,
                validator: validateWebsite,
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 24),
              CustomButton(text: 'Next', onPressed: () async{
                if (_formKey.currentState!.validate()) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportFraudStep2(
                        fraudType: fraudType ?? '',
                        name:name,
                        phone: phone,
                        email: email,
                        website: website,

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
}
