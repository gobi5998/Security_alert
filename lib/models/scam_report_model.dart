import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/sync_service.dart';
part 'scam_report_model.g.dart';

@HiveType(typeId: 1)
class ScamReportModel extends HiveObject implements SyncableReport {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

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

  ScamReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.date,
    this.isSynced = false,
    this.screenshotPaths = const [],
    this.documentPaths = const [],
    this.phone,
    this.email,
    this.website,
  });

  @override
  Map<String, dynamic> toSyncJson() => {
    'title': title,
    'description': description,
    'type': type,
    'severity': severity,
    'date': date.toIso8601String(),
  };

  @override
  String get endpoint => 'scam-reports';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'severity': severity,
    'date': date.toIso8601String(),
    'isSynced': isSynced,
  };

  static ScamReportModel fromJson(Map<String, dynamic> json) => ScamReportModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    type: json['type'] as String,
    severity: json['severity'] as String,
    date: DateTime.parse(json['date'] as String),
    isSynced: json['isSynced'] as bool? ?? false,
  );
}

// This model is used only in memory or encoded as JSON, not stored in Hive.
class MalwareReport {
  final String? malwareType;
  final String? infectedDeviceType;
  final String? operatingSystem;
  final String? detectionMethod;
  final String? location;
  final String? fileName;
  final String? name;
  final String? systemAffected;
  final String? alertSeverityLevel;

  MalwareReport({
    this.malwareType,
    this.infectedDeviceType,
    this.operatingSystem,
    this.detectionMethod,
    this.location,
    this.fileName,
    this.name,
    this.systemAffected,
    this.alertSeverityLevel,
  });

  factory MalwareReport.fromJson(Map<String, dynamic> json) {
    return MalwareReport(
      malwareType: json['malwareType'],
      infectedDeviceType: json['infectedDeviceType'],
      operatingSystem: json['operatingSystem'],
      detectionMethod: json['detectionMethod'],
      location: json['location'],
      fileName: json['fileName'],
      name: json['name'],
      systemAffected: json['systemAffected'],
      alertSeverityLevel: json['alertSeverityLevel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'malwareType': malwareType,
      'infectedDeviceType': infectedDeviceType,
      'operatingSystem': operatingSystem,
      'detectionMethod': detectionMethod,
      'location': location,
      'fileName': fileName,
      'name': name,
      'systemAffected': systemAffected,
      'alertSeverityLevel': alertSeverityLevel,
    };
  }

  static List<MalwareReport> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((e) => MalwareReport.fromJson(e)).toList();
  }

  static String encodeList(List<MalwareReport> reports) =>
      jsonEncode(reports.map((e) => e.toJson()).toList());

  static List<MalwareReport> decodeList(String reports) =>
      (jsonDecode(reports) as List<dynamic>)
          .map((e) => MalwareReport.fromJson(e))
          .toList();
}
