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


// class ReportFraudStep1 extends StatefulWidget {
//   const ReportFraudStep1({Key? key}) : super(key: key);
//
//   @override
//   State<ReportFraudStep1> createState() => _ReportFraudStep1State();
// }
//
// class _ReportFraudStep1State extends State<ReportFraudStep1> {
//   final _formKey = GlobalKey<FormState>();
//   String? fraudType,name,phoneNumber, email, website;
//   bool _isOnline = true;
//
//   final List<String> fraudTypes = [
//     'Phishing',
//     'Lottery',
//     'Investment',
//     'Romance',
//     'Tech Support',
//     'Other',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initHive();
//     _setupConnectivityListener();
//   }
//
//   Future<void> _initHive() async {
//     final dir = await getApplicationDocumentsDirectory();
//     Hive.init(dir.path);
//     await Hive.openBox<FraudReportModel>('Fraud_reports');
//   }
//
//   void _setupConnectivityListener() {
//     Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       setState(() {
//         _isOnline = result != ConnectivityResult.none;
//       });
//       if (_isOnline) {
//         print('Internet connection restored, syncing reports...');
//         FraudReportService.syncReports();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Report Fraud'),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               CustomDropdown(label: 'Fraud Type', hint: 'Select a Fraud Type',
//                 items: fraudTypes, value: fraudType,
//                 onChanged: (val) => setState(() => fraudType = val),),
//
//               const SizedBox(height: 16),
//               const Text(
//                 'Fraudmer details',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               CustomTextField(label: 'Name*',hintText: 'John deo',
//                 onChanged:(val) => name = val,
//                 keyboardType: TextInputType.phone,
//                 validator: validatePhone,
//               ),
//
//               const SizedBox(height: 8),
//               CustomTextField(label: 'Phone*',hintText: '+91-979864483',
//                 onChanged:(val) => phoneNumber = val,
//                 keyboardType: TextInputType.phone,
//                 validator: validatePhone,
//               ),
//
//               const SizedBox(height: 12),
//               CustomTextField(label: 'Email*',hintText: 'fathanah@gmail.com',
//                 onChanged:(val) => email = val,
//                 keyboardType: TextInputType.emailAddress,
//                 validator: validateEmail,
//               ),
//
//               const SizedBox(height: 12),
//               CustomTextField(label: 'Website',hintText: 'www.fathanah.com',
//                 onChanged:(val) => website = val,
//                 keyboardType: TextInputType.webSearch,
//                 validator: validateWebsite,
//               ),
//
//               const SizedBox(height: 12),
//
//               const SizedBox(height: 24),
//               CustomButton(text: 'Next', onPressed: () async{
//                 if (_formKey.currentState!.validate()) {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ReportFraudStep2(
//                         fraudType: fraudType ?? '',
//                         name:name,
//                         phoneNumber: phoneNumber,
//                         email: email,
//                         website: website,
//
//                       ),
//                     ),
//                   );
//                 }
//                 return;
//               },
//                   fontWeight: FontWeight.normal),
//
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


class ReportScam1 extends StatefulWidget {
  final String categoryId;
  const ReportScam1({required this.categoryId});

  @override
  State<ReportScam1> createState() => _ReportScam1State();
}

class _ReportScam1State extends State<ReportScam1> {
  final _formKey = GlobalKey<FormState>();
  String? scamTypeId, phoneNumber, email, website, description;
  List<Map<String, dynamic>> scamTypes = [];
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadScamTypes();
    _setupNetworkListener();
  }

  void _setupNetworkListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() => isOnline = result != ConnectivityResult.none);
      if (isOnline) FraudReportService.syncReports();
    });
  }

  Future<void> _loadScamTypes() async {
    final box = await Hive.openBox('scam_types');
    // Try to load from Hive first
    final raw = box.get(widget.categoryId);
    List<Map<String, dynamic>>? cachedTypes;
    if (raw != null) {
      cachedTypes = (raw as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    if (cachedTypes != null && cachedTypes.isNotEmpty) {
      scamTypes = cachedTypes;
      setState(() {});
    }

    // Always try to fetch latest from backend in background
    try {
      final latestTypes = await FraudReportService.fetchReportTypesByCategory(widget.categoryId);
      if (latestTypes != null && latestTypes.isNotEmpty) {
        scamTypes = latestTypes;
        await box.put(widget.categoryId, latestTypes);
        setState(() {});
      }
    } catch (e) {
      // If offline or error, just use cached
      print('Failed to fetch latest scam types: $e');
    }
  }

  Future<void> _submitForm() async {

    if (_formKey.currentState!.validate()) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final report = FraudReportModel(
        id: id,
        reportCategoryId: widget.categoryId,
        reportTypeId: scamTypeId!,
        alertLevels: 'low',
        phoneNumber: phoneNumber ?? '',
        email: email!,
        website: website ?? '',
        description: description!,

      );

      await FraudReportService.saveReport(report);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportFraudStep2(report: report, fraudType: '',),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report Scam')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [


            CustomDropdown(
              label: 'Scam Type',
              hint: 'Select a Scam Type',
              items: scamTypes.map((e) => e['name'] as String).toList(),
              value: scamTypes.firstWhere(
                    (e) => e['_id'] == scamTypeId,
                orElse: () => {},
              )['name'],
              onChanged: (val) {
                setState(() {
                  scamTypeId = val;
                  scamTypeId = scamTypes.firstWhere((e) => e['name'] == val)['_id'];
                });
              },
            ),

            const SizedBox(height: 12),
            CustomTextField(label: 'Phone', hintText: 'Phone',
              onChanged: (val) => phoneNumber = val,validator: validatePhone,),


            const SizedBox(height: 12),
            CustomTextField(label: 'email', hintText: 'email',
              onChanged: (val) => email = val,validator: validateEmail,),
            const SizedBox(height: 12),
            CustomTextField(label: 'Website', hintText: 'Website',
              onChanged: (val) => website = val,validator: validateWebsite,),
            const SizedBox(height: 12),
            CustomTextField(label: 'Description', hintText: 'Description',
              onChanged: (val) => description = val,validator: validateDescription,),


            SizedBox(height: 24),
            CustomButton(text: 'Next', onPressed: _submitForm, fontWeight: FontWeight.normal),

          ],
        ),
      ),
    );
  }
}