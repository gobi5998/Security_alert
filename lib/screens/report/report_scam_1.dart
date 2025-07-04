import 'package:flutter/material.dart';
import 'package:security_alert/custom/customDescription.dart';
import 'package:security_alert/screens/report/report_scam_2.dart';
import '../../custom/CustomDropdown.dart';
import '../../custom/customButton.dart';
import '../../custom/customTextfield.dart';

class ScamReportPage1 extends StatefulWidget {
  const ScamReportPage1({super.key});

  @override
  State<ScamReportPage1> createState() => _ScamReportPage1State();
}

class _ScamReportPage1State extends State<ScamReportPage1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _scamType;

  void goToNextPage() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScamReportPage2(
            phone: _phoneController.text,
            email: _emailController.text,
            website: _websiteController.text,
            description: _descriptionController.text,
            scamType: _scamType,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Scam')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomDropdown(
                        label: "Scam Type",
                        hint: "Select a Scam Type",
                        value: _scamType,
                        items: const ['Phishing', 'Investment', 'Romance'],
                        onChanged: (val) => setState(() => _scamType = val),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(controller: _phoneController, hintText: "+91-XXXXXXX", label: 'Phone',),
                      const SizedBox(height: 16),
                      CustomTextField(controller: _emailController, hintText: "email@example.com", label: 'Email',),
                      const SizedBox(height: 16),
                      CustomTextField(controller: _websiteController, hintText: "www.example.com", label: 'Website',),
                      const SizedBox(height: 16),
                      CustomDescription(
                        controller: _descriptionController,
                        hintText: "Describe scam",
                        maxLines: 5,
                        label: 'CustomDescription',
                        hint: 'Something Type',
                      ),
                      const SizedBox(height: 24),
                      CustomButton(text: 'Next', onPressed: () async {
                        Navigator.push(context, MaterialPageRoute(builder: (context) =>  ScamReportPage2(phone: _phoneController.text,
                          email: _emailController.text,
                          website: _websiteController.text,
                          description: _descriptionController.text,
                          scamType: _scamType,)));
                        return;
                      },
                        fontSize: 20,
                        borderCircular: 6,
                        fontWeight: FontWeight.bold,),

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
