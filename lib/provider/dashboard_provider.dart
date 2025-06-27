import 'package:flutter/material.dart';

class DashboardProvider with ChangeNotifier {
  final Map<String, double> reportedFeatures = {
    'Reported Spam': 0.28,
    'Reported Malware': 0.68,
    'Reported Fraud': 0.50,
    'Others': 0.04,
  };

  List<double> threatDataLine = [30, 35, 40, 50, 45, 38, 42];
  List<int> threatDataBar = [10, 20, 15, 30, 25, 20, 10];
  String selectedTab = '1D';

  void changeTab(String tab) {
    selectedTab = tab;
    // TODO: Change data based on tab
    notifyListeners();
  }
}
