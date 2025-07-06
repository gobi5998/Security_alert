import 'package:hive/hive.dart';

import '../../models/scam_report_model.dart';

class ScamLocalService {
  static const String boxName = 'scam_reports';

  Future<void> addReport(ScamReportModel report) async {
    final box = await Hive.openBox<ScamReportModel>(boxName);
    await box.put(report.id, report);
  }

  Future<List<ScamReportModel>> getAllReports() async {
    final box = await Hive.openBox<ScamReportModel>(boxName);
    return box.values.toList();
  }

  Future<void> updateReport(ScamReportModel report) async {
    final box = await Hive.openBox<ScamReportModel>(boxName);
    await box.put(report.id, report);
  }

  Future<void> deleteReport(String id) async {
    final box = await Hive.openBox<ScamReportModel>(boxName);
    await box.delete(id);
  }
}
