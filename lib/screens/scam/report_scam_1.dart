import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:security_alert/custom/CustomDropdown.dart';
import 'package:security_alert/custom/customButton.dart';
import 'package:security_alert/custom/customTextfield.dart';
import 'package:security_alert/custom/customValidator.dart';
import '../../models/scam_report_model.dart';
import 'report_scam_2.dart';
import 'view_pending_reports.dart';
import 'scam_report_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// class ReportScam1 extends StatefulWidget {
//   final String categoryId;
//   const ReportScam1({Key? key, required this.categoryId}) : super(key: key);

//   @override
//   State<ReportScam1> createState() => _ReportScam1State();
// }

// class _ReportScam1State extends State<ReportScam1> {
//   final _formKey = GlobalKey<FormState>();
//   String? scamType, phone, email, website, description;
//   bool _isOnline = true;

//   List<Map<String, dynamic>> scamTypes = [];
//   String? scamTypeId; // This will store the selected id

//   @override
//   void initState() {
//     super.initState();
//     _initHive();
//     _setupConnectivityListener();
//     _loadScamTypes();
//   }

//   Future<void> _initHive() async {
//     final dir = await getApplicationDocumentsDirectory();
//     Hive.init(dir.path);
//     await Hive.openBox<ScamReportModel>('scam_reports');
//   }

//   Future<void> _loadScamTypes() async {
//     // Call your API service with widget.categoryId
//     scamTypes = await ScamReportService.fetchReportTypesByCategory(widget.categoryId);
//     setState(() {});
//   }

//   void _setupConnectivityListener() {
//     Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       setState(() {
//         _isOnline = result != ConnectivityResult.none;
//       });
//       if (_isOnline) {
//         print('Internet connection restored, syncing reports...');
//         ScamReportService.syncReports();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Report Scam'),
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
//               CustomDropdown(
//                 label: 'Scam Type',
//                 hint: 'Select a Scam Type',
//                 items: scamTypes.map((e) => e['name'] as String).toList(),
//                 value: scamTypes.firstWhere(
//                   (e) => e['_id'] == scamTypeId,
//                   orElse: () => {},
//                 )['name'],
//                 onChanged: (val) {
//                   setState(() {
//                     scamTypeId = scamTypes.firstWhere((e) => e['name'] == val)['_id'];
//                   });
//                 },
//               ),

// const SizedBox(height: 16),
// const Text(
//   'Scammer details',
//   style: TextStyle(fontWeight: FontWeight.bold),
// ),
//               const SizedBox(height: 8),
//               CustomTextField(label: 'Phone*',hintText: '+91-979864483',
//                 onChanged:(val) => phone = val,
//                 keyboardType: TextInputType.phone,
//                 validator: validatePhone,
//                  ),

//               const SizedBox(height: 12),
//               CustomTextField(label: 'Email*',hintText: 'fathanah@gmail.com',
//                 onChanged:(val) => email = val,
//                 keyboardType: TextInputType.emailAddress,
//                 validator: validateEmail,
//                ),

//               const SizedBox(height: 12),
//               CustomTextField(label: 'Website',hintText: 'www.fathanah.com',
//                 onChanged:(val) => website = val,
//                 keyboardType: TextInputType.webSearch,
//                 validator: validateWebsite,
//                 ),

//               const SizedBox(height: 12),
//               CustomTextField(label: 'Description*',hintText: 'Describe the scam...',
//                 onChanged:(val) => description = val,
//                 keyboardType: TextInputType.text,
//                 validator: validateDescription,
//                 ),
//               // TextFormField(
//               //   maxLines: 4,
//               //   decoration: const InputDecoration(
//               //     labelText: 'Description',
//               //     hintText: 'Describe the scam...',
//               //     border: OutlineInputBorder(),
//               //   ),
//               //   onChanged: (val) => description = val,
//               // ),
//               const SizedBox(height: 24),
//               // CustomButton(text: 'Next', onPressed: () async{
//               //   if (_formKey.currentState!.validate()) {
//               //     Navigator.push(
//               //       context,
//               //       MaterialPageRoute(
//               //         builder: (context) => ReportScam2(
//               //           scamType: scamType ?? '',
//               //           phone: phone,
//               //           email: email,
//               //           website: website,
//               //           description: description,
//               //         ),
//               //       ),
//               //     );
//               //   }
//               //   return;
//               // },
//               //     fontWeight: FontWeight.normal),

//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> submitMalwareReport(ScamReportModel report) async {
//     // Use the centralized service to save and sync the report
//     await ScamReportService.saveReport(report);

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(report.isSynced
//             ? 'Report sent and saved as synced!'
//             : 'Report saved locally. Will sync when connection is restored.'),
//           backgroundColor: report.isSynced ? Colors.green : Colors.orange,
//         ),
//       );
//     }
//   }
// }

// class ReportScam1 extends StatefulWidget {
//   final String categoryId;
//   const ReportScam1({required this.categoryId});
//
//   @override
//   State<ReportScam1> createState() => _ReportScam1State();
// }
//
// class _ReportScam1State extends State<ReportScam1> {
//   final _formKey = GlobalKey<FormState>();
//   String? scamType,scamTypeId, phone, email, website, description;
//   List<Map<String, dynamic>> scamTypes = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadScamTypes();
//   }
//
//   Future<void> _loadScamTypes() async {
//     scamTypes = await ScamReportService.fetchReportTypesByCategory(widget.categoryId);
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Report Scam')),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: EdgeInsets.all(20),
//           children: [
//             CustomDropdown(
//               label: 'Scam Type',
//               hint: 'Select a Scam Type',
//               items: scamTypes.map((e) => e['name'] as String).toList(),
//               value: scamTypes.firstWhere(
//                 (e) => e['_id'] == scamTypeId,
//                 orElse: () => {},
//               )['name'],
//               onChanged: (val) {
//                 setState(() {
//                   scamTypeId = scamTypes.firstWhere((e) => e['name'] == val)['_id'];
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Scammer details',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             CustomTextField(
//               label: 'Phone*',
//               hintText: '+91-979864483',
//               onChanged: (val) => phone = val,
//               keyboardType: TextInputType.phone,
//               validator: validatePhone,
//             ),
//             const SizedBox(height: 12),
//             CustomTextField(
//               label: 'Email*',
//               hintText: 'fathanah@gmail.com',
//               onChanged: (val) => email = val,
//               keyboardType: TextInputType.emailAddress,
//               validator: validateEmail,
//             ),
//             const SizedBox(height: 12),
//             CustomTextField(
//               label: 'Website',
//               hintText: 'www.fathanah.com',
//               onChanged: (val) => website = val,
//               keyboardType: TextInputType.url,
//               validator: validateWebsite,
//             ),
//             const SizedBox(height: 12),
//             CustomTextField(
//               label: 'Description*',
//               hintText: 'Describe the scam...',
//               onChanged: (val) => description = val,
//               keyboardType: TextInputType.text,
//               validator: validateDescription,
//             ),
//             const SizedBox(height: 24),
//         CustomButton(text: 'Next', onPressed: () async{
//           if (_formKey.currentState!.validate()) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => ReportScam2(
//                   scamType: scamType ?? '',
//                   phone: phone,
//                   email: email,
//                   website: website,
//                   description: description,
//                 ),
//               ),
//             );
//           }
//           return;
//         },
//             fontWeight: FontWeight.normal),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ReportScam1 extends StatefulWidget {
//   final String categoryId;
//   const ReportScam1({required this.categoryId});
//
//   @override
//   State<ReportScam1> createState() => _ReportScam1State();
// }
//
// class _ReportScam1State extends State<ReportScam1> {
//   final _formKey = GlobalKey<FormState>();
//   String? scamTypeId, scamType, phone, email, website, description;
//   List<Map<String, dynamic>> scamTypes = [];
//   bool isOnline = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadScamTypes();
//     _setupNetworkListener();
//   }
//
//   void _setupNetworkListener() {
//     Connectivity().onConnectivityChanged.listen((result) {
//       setState(() => isOnline = result != ConnectivityResult.none);
//       if (isOnline) ScamReportService.syncReports();
//     });
//   }
//
//   Future<void> _loadScamTypes() async {
//     scamTypes = await ScamReportService.fetchReportTypesByCategory(widget.categoryId);
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Report Scam')),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: EdgeInsets.all(20),
//           children: [
//             CustomDropdown(
//               label: 'Scam Type',
//               hint: 'Select a Scam Type',
//               items: scamTypes.map((e) => e['name'] as String).toList(),
//               value: scamTypes.firstWhere(
//                     (e) => e['_id'] == scamTypeId,
//                 orElse: () => {},
//               )['name'],
//               onChanged: (val) {
//                 setState(() {
//                   scamType = val;
//                   scamTypeId = scamTypes.firstWhere((e) => e['name'] == val)['_id'];
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
//             const Text('Scammer details', style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             CustomTextField(
//               label: 'Phone*',
//               hintText: '+91-979864483',
//               onChanged: (val) => phone = val,
//               keyboardType: TextInputType.phone,
//               validator: validatePhone,
//             ),
//             const SizedBox(height: 12),
//             CustomTextField(
//               label: 'Email*',
//               hintText: 'example@gmail.com',
//               onChanged: (val) => email = val,
//               keyboardType: TextInputType.emailAddress,
//               validator: validateEmail,
//             ),
//             const SizedBox(height: 12),
//             CustomTextField(
//               label: 'Website',
//               hintText: 'www.example.com',
//               onChanged: (val) => website = val,
//               keyboardType: TextInputType.url,
//               validator: validateWebsite,
//             ),
//             const SizedBox(height: 12),
//             CustomTextField(
//               label: 'Description*',
//               hintText: 'Describe the scam...',
//               onChanged: (val) => description = val,
//               keyboardType: TextInputType.text,
//               validator: validateDescription,
//             ),
//             const SizedBox(height: 24),
//             CustomButton(
//               text: 'Next',
//               onPressed: () async {
//                 if (_formKey.currentState!.validate()) {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ReportScam2(
//                         report: ScamReportModel(
//                           id: '', // or generate an id
//                           title: scamType ?? '',
//                           description: description ?? '',
//                           type: scamType ?? '',
//                           severity: '', // fill as needed
//                           date: DateTime.now(),
//                           email: email ?? '',
//                           phone: phone ?? '',
//                           website: website ?? '',
//                           isSynced: false,
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//               },
//               fontWeight: FontWeight.normal,
//             ),
//           ],
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
      if (isOnline) ScamReportService.syncReports();
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
      final latestTypes = await ScamReportService.fetchReportTypesByCategory(
        widget.categoryId,
      );
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
      final report = ScamReportModel(
        id: id,
        reportCategoryId: widget.categoryId,
        reportTypeId: scamTypeId!,
        alertLevels: 'low',
        phoneNumber: phoneNumber ?? '',
        email: email!,
        website: website ?? '',
        description: description!,
      );

      await ScamReportService.saveReport(report);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportScam2(report: report)),
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
                  scamTypeId = scamTypes.firstWhere(
                    (e) => e['name'] == val,
                  )['_id'];
                });
              },
            ),

            const SizedBox(height: 12),
            CustomTextField(
              label: 'Phone',
              hintText: 'Phone',
              onChanged: (val) => phoneNumber = val,
              validator: validatePhone,
            ),

            const SizedBox(height: 12),
            CustomTextField(
              label: 'Email',
              hintText: 'Email',
              onChanged: (val) => email = val,
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Website',
              hintText: 'Website',
              onChanged: (val) => website = val,
              validator: validateWebsite,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Description',
              hintText: 'Description',
              onChanged: (val) => description = val,
              validator: validateDescription,
            ),

            SizedBox(height: 24),
            CustomButton(
              text: 'Next',
              onPressed: _submitForm,
              fontWeight: FontWeight.normal,
            ),
          ],
        ),
      ),
    );
  }
}
