import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../models/scam_report_provider.dart';


class ViewPendingReports extends StatelessWidget {
  const ViewPendingReports({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScamReportProvider>(context);
    final pending = provider.reports.where((r) => !r.isSynced).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Pending Reports')),
      body: ListView.builder(
        itemCount: pending.length,
        itemBuilder: (context, i) {
          final report = pending[i];
          return ListTile(
            title: Text(report.title),
            subtitle: Text(report.description),
            trailing: Icon(Icons.sync_problem, color: Colors.orange),
          );
        },
      ),
    );
  }
}
