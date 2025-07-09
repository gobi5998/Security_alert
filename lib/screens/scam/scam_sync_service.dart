import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/scam_report_model.dart';
import 'scam_local_service.dart';
import 'scam_remote_service.dart';

class ScamSyncService {
  final ScamLocalService _localService = ScamLocalService();
  final ScamRemoteService _remoteService = ScamRemoteService();

  Future<void> syncReports() async {
    try {
      var connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        print('No internet connection available for sync');
        return;
      }

      print('Starting sync process...');
      List<ScamReportModel> reports = await _localService.getAllReports();
      List<ScamReportModel> unsyncedReports = reports.where((r) => !r.isSynced).toList();
      
      print('Found ${unsyncedReports.length} unsynced reports to sync');

      for (var report in unsyncedReports) {
        try {
          print('Syncing report: ${report.id} - ${report.title}');
          bool success = await _remoteService.sendReport(report);
          
          if (success) {
            report.isSynced = true;
            await _localService.updateReport(report);
            print('Successfully synced report: ${report.id}');
          } else {
            print('Failed to sync report: ${report.id}');
          }
        } catch (e) {
          print('Error syncing report ${report.id}: $e');
        }
      }
      
      print('Sync process completed');
    } catch (e) {
      print('Error in sync process: $e');
    }
  }

  Future<bool> syncSingleReport(ScamReportModel report) async {
    try {
      var connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        print('No internet connection available for single report sync');
        return false;
      }

      print('Syncing single report: ${report.id}');
      bool success = await _remoteService.sendReport(report);
      
      if (success) {
        report.isSynced = true;
        await _localService.updateReport(report);
        print('Successfully synced single report: ${report.id}');
        return true;
      } else {
        print('Failed to sync single report: ${report.id}');
        return false;
      }
    } catch (e) {
      print('Error syncing single report ${report.id}: $e');
      return false;
    }
  }
}
