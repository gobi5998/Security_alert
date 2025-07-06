import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/scam_report_model.dart';
import 'scam_local_service.dart';

import 'scam_remote_service.dart';

class ScamSyncService {
  final ScamLocalService _localService = ScamLocalService();
  final ScamRemoteService _remoteService = ScamRemoteService();

  Future<void> syncReports() async {
    var connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    List<ScamReportModel> reports = await _localService.getAllReports();
    for (var report in reports.where((r) => !r.isSynced)) {
      bool success = await _remoteService.sendReport(report);
      if (success) {
        report.isSynced = true;
        await _localService.updateReport(report);
      }
    }
  }
}
