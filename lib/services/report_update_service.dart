import '../screens/scam/scam_report_service.dart';
import '../screens/Fraud/fraud_report_service.dart';

class ReportUpdateService {
  static Future<void> updateAllExistingReports() async {
    try {
      // Update existing scam reports
      await ScamReportService.updateExistingReportsWithKeycloakUserId();
      print('Updated existing scam reports with keycloakUserId');

      // Update existing fraud reports
      await FraudReportService.updateExistingReportsWithKeycloakUserId();
      print('Updated existing fraud reports with keycloakUserId');
    } catch (e) {
      print('Error updating existing reports: $e');
    }
  }
}
