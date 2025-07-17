import 'package:flutter/material.dart';
import 'package:security_alert/screens/menu/thread_database_listpage.dart';


class ThreadDatabaseFilterPage extends StatefulWidget {
  @override
  State<ThreadDatabaseFilterPage> createState() =>
      _ThreadDatabaseFilterPageState();
}

class _ThreadDatabaseFilterPageState extends State<ThreadDatabaseFilterPage> {
  String searchQuery = '';
  String? selectedType;
  String? selectedSeverity;

  final List<String> scamTypes = [
    'Phishing',
    'Lottery',
    'Investment',
    'Romance',
    'Tech Support',
    'Other',
  ];
  final List<String> severityLevels = ['Low', 'Medium', 'High', 'Critical'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thread Database'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [IconButton(icon: Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Search and filter through our database of reported scams and malware threats.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              value: selectedType,
              items: scamTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
              )
                  .toList(),
              onChanged: (val) => setState(() => selectedType = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Alert Severity Levels',
                border: OutlineInputBorder(),
              ),
              value: selectedSeverity,
              items: severityLevels
                  .map(
                    (level) =>
                    DropdownMenuItem(value: level, child: Text(level)),
              )
                  .toList(),
              onChanged: (val) => setState(() => selectedSeverity = val),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ThreadDatabaseListPage(
                      searchQuery: '',
                      selectedType: null,
                      selectedSeverity: null, scamTypeId: '',
                    ),
                  ),
                );
              },
              child: Text(
                'View All Report',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThreadDatabaseListPage(
                        searchQuery: searchQuery,
                        selectedType: selectedType,
                        selectedSeverity: selectedSeverity, scamTypeId: '',
                      ),
                    ),
                  );
                },
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
