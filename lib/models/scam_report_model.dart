import 'package:hive/hive.dart';
import '../services/sync_service.dart';

part 'scam_report_model.g.dart';

@HiveType(typeId: 0)
class ScamReportModel extends HiveObject {
  @HiveField(0)
  String? id; // maps to _id

  @HiveField(1)
  String? reportCategoryId;

  @HiveField(2)
  String? reportTypeId;

  @HiveField(3)
  String? alertLevels;

  @HiveField(4)
  String? phoneNumber; // store as String for flexibility

  @HiveField(5)
  String? email;

  @HiveField(6)
  String? website;

  @HiveField(7)
  String? description;

  @HiveField(8)
  DateTime? createdAt;

  @HiveField(9)
  DateTime? updatedAt;

  @HiveField(10)
  bool? isSynced;

  @HiveField(11)
  List<String> screenshotPaths;

  @HiveField(12)
  List<String> documentPaths;

  @HiveField(13)
  String? name;

  @HiveField(14)
  String? keycloakUserId; // Keycloak user ID from JWT token sub field

  // Add other fields as needed

  ScamReportModel({
    this.id,
    this.reportCategoryId,
    this.reportTypeId,
    this.alertLevels,
    this.phoneNumber,
    this.email,
    this.website,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.screenshotPaths = const [],
    this.documentPaths = const [],
    this.name,
    this.keycloakUserId,
  });

  Map<String, dynamic> toJson() => {
    '_id': id,
    'reportCategoryId': reportCategoryId,
    'reportTypeId': reportTypeId,
    'alertLevels': alertLevels,
    'name': name,
    // If backend expects int, convert here:
    'phoneNumber': int.tryParse(phoneNumber ?? '') ?? 0,
    'email': email,
    'website': website,
    'description': description,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isSynced': isSynced,
    'screenshotPaths': screenshotPaths,
    'documentPaths': documentPaths,
    'keycloackUserId': keycloakUserId,
  };

  factory ScamReportModel.fromJson(
    Map<String, dynamic> json,
  ) => ScamReportModel(
    id: json['id'] ?? json['_id'],
    reportCategoryId: json['reportCategoryId'],
    reportTypeId: json['reportTypeId'],
    alertLevels: json['alertLevels'],
    name: json['name'],
    phoneNumber: json['phoneNumber'],
    email: json['email'],
    website: json['website'],
    description: json['description'],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'])
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'])
        : null,
    isSynced: json['isSynced'],
    screenshotPaths:
        (json['screenshotPaths'] as List?)?.map((e) => e as String).toList() ??
        [],
    documentPaths:
        (json['documentPaths'] as List?)?.map((e) => e as String).toList() ??
        [],
    keycloakUserId: json['keycloackUserId'],
  );

  ScamReportModel copyWith({
    String? id,
    String? reportCategoryId,
    String? reportTypeId,
    String? alertLevels,
    String? name,
    String? phoneNumber,
    String? email,
    String? website,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    List<String>? screenshotPaths,
    List<String>? documentPaths,
    String? keycloakUserId,
  }) {
    return ScamReportModel(
      id: id ?? this.id,
      reportCategoryId: reportCategoryId ?? this.reportCategoryId,
      reportTypeId: reportTypeId ?? this.reportTypeId,
      alertLevels: alertLevels ?? this.alertLevels,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      screenshotPaths: screenshotPaths ?? this.screenshotPaths,
      documentPaths: documentPaths ?? this.documentPaths,
      keycloakUserId: keycloakUserId ?? this.keycloakUserId,
    );
  }
}
