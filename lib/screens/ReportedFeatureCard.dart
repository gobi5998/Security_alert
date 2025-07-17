import 'package:flutter/material.dart';

import 'ReportedFeatureItem.dart';

class ReportedFeaturesPanel extends StatefulWidget {
  const ReportedFeaturesPanel({super.key});

  @override
  State<ReportedFeaturesPanel> createState() => _ReportedFeaturesPanelState();
}

class _ReportedFeaturesPanelState extends State<ReportedFeaturesPanel> {
  String selectedPeriod = 'Weekly';
  final List<String> periods = ['Weekly', 'Monthly', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3D70).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Reported Features",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: selectedPeriod,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  dropdownColor: Colors.blue.shade800,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value!;
                    });
                  },
                  items: periods
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Report Items
          ReportedFeatureItem(
            iconPath: 'assets/icon/scam.png',
            title: 'Reported Scam',
            progress: 0.28,
            percentage: '28%',
            onAdd: '/thread',
          ),
          ReportedFeatureItem(
            iconPath: 'assets/icon/malware.png',
            title: 'Reported Malware',
            progress: 0.68,
            percentage: '68%',
            onAdd: '/thread',
          ),
          ReportedFeatureItem(
            iconPath: 'assets/icon/fraud.png',
            title: 'Reported Fraud',
            progress: 0.50,
            percentage: '50%',
            onAdd:'/thread',
          ),
          ReportedFeatureItem(
            iconPath: 'assets/icon/due.png',
            title: 'Due Diligence',
            progress: 0.04,
            percentage: '04%',
            onAdd: '/thread',
          ),

        ],
      ),
    );
  }
}