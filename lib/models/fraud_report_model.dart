import 'package:hive/hive.dart';
import '../services/sync_service.dart';
part 'fraud_report_model.g.dart';

@HiveType(typeId: 1)
class Fraudreportmodel extends HiveObject implements SyncableReport {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String name;

  @HiveField(3)
  String type;

  @HiveField(4)
  String severity;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  bool isSynced;

  @HiveField(7)
  List<String> screenshotPaths;

  @HiveField(8)
  List<String> documentPaths;

  @HiveField(9)
  String? phone;

  @HiveField(10)
  String? email;

  @HiveField(11)
  String? website;

  @HiveField(12)
  List<String> voicePaths;

  Fraudreportmodel({
    required this.id,
    required this.title,
    required this.name,
    required this.type,
    required this.severity,
    required this.date,
    this.isSynced = false,
    this.screenshotPaths = const [],
    this.documentPaths = const [],
    this.voicePaths = const [],
    this.phone,
    this.email,
    this.website,
  });

  @override
  Map<String, dynamic> toSyncJson() => {
    'title': title,
    'name': name,
    'type': type,
    'severity': severity,
    'date': date.toIso8601String(),
    'screenshotPaths':screenshotPaths,
    'documentPaths':documentPaths,
    'voicePaths':voicePaths,
  };

  @override
  String get endpoint => 'scam-reports';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'name': name,
    'type': type,
    'severity': severity,
    'date': date.toIso8601String(),
    'screenshotPaths':screenshotPaths,
    'documentPaths':documentPaths,
    'voicePaths':voicePaths,
    'isSynced': isSynced,
  };

  static Fraudreportmodel fromJson(Map<String, dynamic> json) => Fraudreportmodel(
    id: json['id'] as String,
    title: json['title'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    severity: json['severity'] as String,
    date: DateTime.parse(json['date'] as String),
    screenshotPaths: json['screenshotPaths'] ,
    documentPaths: json['documentPaths'] ,
    voicePaths: json['voicePaths'],
    isSynced: json['isSynced'] as bool? ?? false,

  );
}

//