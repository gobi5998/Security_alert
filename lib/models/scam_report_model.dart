// import 'dart:convert';
// import 'package:hive/hive.dart';

// part 'scam_report_model.g.dart';

// @HiveType(typeId: 1)
// class ScamReportModel extends HiveObject {
//   @HiveField(0)
//   String id;

//   @HiveField(1)
//   String title;

//   @HiveField(2)
//   String phone;

//   @HiveField(3)
//   String email;

//   @HiveField(4)
//   String website;

//   @HiveField(5)
//   String description;

//   @HiveField(6)
//   String type;

//   @HiveField(7)
//   String severity;

//   @HiveField(8)
//   DateTime date;

//   @HiveField(9)
//   bool isSynced;

//   ScamReportModel({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.type,
//     required this.severity,
//     required this.date,
//     required this.email,
//     required this.phone,
//     required this.website,
//     this.isSynced = false,
//   });

//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'title': title,
//     'email':email,
//     'phone':phone,
//     'website':website,
//     'description': description,
//     'type': type,
//     'severity': severity,
//     'date': date.toIso8601String(),
//     'isSynced': isSynced,
//   };

//   static ScamReportModel fromJson(Map<String, dynamic> json) => ScamReportModel(
//     id: json['id'] as String,
//     title: json['title'] as String,
//     email: json['email'] as String,
//     phone: json['phone'] as String,
//     website: json['website'] as String,
//     description: json['description'] as String,
//     type: json['type'] as String,
//     severity: json['severity'] as String,
//     date: DateTime.parse(json['date'] as String),
//     isSynced: json['isSynced'] as bool? ?? false,
//   );
// }

// // This model is used only in memory or encoded as JSON, not stored in Hive.
// class MalwareReport {
//   final String? malwareType;
//   final String? infectedDeviceType;
//   final String? operatingSystem;
//   final String? detectionMethod;
//   final String? location;
//   final String? fileName;
//   final String? name;
//   final String? systemAffected;
//   final String? alertSeverityLevel;

//   MalwareReport({
//     this.malwareType,
//     this.infectedDeviceType,
//     this.operatingSystem,
//     this.detectionMethod,
//     this.location,
//     this.fileName,
//     this.name,
//     this.systemAffected,
//     this.alertSeverityLevel,
//   });

//   factory MalwareReport.fromJson(Map<String, dynamic> json) {
//     return MalwareReport(
//       malwareType: json['malwareType'],
//       infectedDeviceType: json['infectedDeviceType'],
//       operatingSystem: json['operatingSystem'],
//       detectionMethod: json['detectionMethod'],
//       location: json['location'],
//       fileName: json['fileName'],
//       name: json['name'],
//       systemAffected: json['systemAffected'],
//       alertSeverityLevel: json['alertSeverityLevel'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'malwareType': malwareType,
//       'infectedDeviceType': infectedDeviceType,
//       'operatingSystem': operatingSystem,
//       'detectionMethod': detectionMethod,
//       'location': location,
//       'fileName': fileName,
//       'name': name,
//       'systemAffected': systemAffected,
//       'alertSeverityLevel': alertSeverityLevel,
//     };
//   }

//   static List<MalwareReport> listFromJson(List<dynamic> jsonList) {
//     return jsonList.map((e) => MalwareReport.fromJson(e)).toList();
//   }

//   static String encodeList(List<MalwareReport> reports) =>
//       jsonEncode(reports.map((e) => e.toJson()).toList());

//   static List<MalwareReport> decodeList(String reports) =>
//       (jsonDecode(reports) as List<dynamic>)
//           .map((e) => MalwareReport.fromJson(e))
//           .toList();
// }


import 'package:hive/hive.dart';
 import 'dart:convert';
part 'scam_report_model.g.dart';

@HiveType(typeId: 1)
class ScamReportModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String website;

  @HiveField(5)
  String description;

  @HiveField(6)
  String type;

  @HiveField(7)
  String severity;

  @HiveField(8)
  DateTime date;

  @HiveField(9)
  bool isSynced;

  ScamReportModel({
    required this.id,
    required this.title,
    required this.email,
    required this.phone,
    required this.website,
    required this.description,
    required this.type,
    required this.severity,
    required this.date,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'email': email,
    'phone': phone,
    'website': website,
    'description': description,
    'type': type,
    'severity': severity,
    'date': date.toIso8601String(),
    'isSynced': isSynced,
  };

  static ScamReportModel fromJson(Map<String, dynamic> json) => ScamReportModel(
    id: json['id'] as String,
    title: json['title'] as String,
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    website: json['website'] as String? ?? '',
    description: json['description'] as String,
    type: json['type'] as String,
    severity: json['severity'] as String,
    date: DateTime.parse(json['date'] as String),
    isSynced: json['isSynced'] as bool? ?? false,
  );
}