import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:security_alert/custom/CustomDropdown.dart';
import 'package:security_alert/custom/customButton.dart';
import 'package:security_alert/custom/customTextfield.dart';
import 'package:security_alert/custom/customValidator.dart';
import '../../models/fraud_report_model.dart';
import 'ReportFraudStep2.dart';
import 'fraud_report_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportFraudStep1 extends StatefulWidget {
  final String categoryId;
  const ReportFraudStep1({required this.categoryId});

  @override
  State<ReportFraudStep1> createState() => _ReportFraudStep1State();
}

class _ReportFraudStep1State extends State<ReportFraudStep1> {
  final _formKey = GlobalKey<FormState>();
  String? scamTypeId, name, phoneNumber, email, website, description;
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
      final latestTypes = await FraudReportService.fetchReportTypesByCategory(
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
    print('Submit button pressed');
    if (_formKey.currentState!.validate()) {
      try {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final fraudReport = FraudReportModel(
          id: id,
          reportCategoryId: widget.categoryId,
          reportTypeId: scamTypeId!,
          alertLevels: 'low',
          name: name ?? '',
          phoneNumber: phoneNumber ?? '',
          email: email!,
          website: website ?? '',
          description: description!,
        );
        print('Saving report...');
        try {
          await FraudReportService.saveReport(fraudReport);
        } catch (e) {
          print('Save failed but continuing: $e');
        }
        print('Navigating to next page...');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportFraudStep2(report: fraudReport),
          ),
        );
      } catch (e, stack) {
        print('Error in _submitForm: $e\n$stack');
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report Fraud')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            CustomDropdown(
              label: 'Fraud Type',
              hint: 'Select a Fraud Type',
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
              label: 'Name',
              hintText: 'Enter name',
              onChanged: (val) => name = val,
              validator: (val) =>
                  val?.isEmpty == true ? 'Name is required' : null,
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
              label: 'email',
              hintText: 'email',
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
