enum AlertSeverity { low, medium, high, critical }

enum AlertType { spam, malware, fraud, phishing, other }

class SecurityAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertType type;
  final DateTime timestamp;
  final bool isResolved;
  final String? location;
  final String? malwareType;
  final String? infectedDeviceType;
  final String? operatingSystem;
  final String? detectionMethod;
  final String? fileName;
  final String? name;
  final String? systemAffected;
  final Map<String, dynamic>? metadata;

  SecurityAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    required this.timestamp,
    required this.isResolved,
    this.location,
    this.malwareType,
    this.infectedDeviceType,
    this.operatingSystem,
    this.detectionMethod,
    this.fileName,
    this.name,
    this.systemAffected,
    this.metadata,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => AlertSeverity.medium,
      ),
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AlertType.other,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isResolved: json['is_resolved'] ?? false,
      location: json['location'],
      malwareType: json['malwareType'],
      infectedDeviceType: json['infectedDeviceType'],
      operatingSystem: json['operatingSystem'],
      detectionMethod: json['detectionMethod'],
      fileName: json['fileName'],
      name: json['name'],
      systemAffected: json['systemAffected'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.toString().split('.').last,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'is_resolved': isResolved,
      'location': location,
      'malwareType': malwareType,
      'infectedDeviceType': infectedDeviceType,
      'operatingSystem': operatingSystem,
      'detectionMethod': detectionMethod,
      'fileName': fileName,
      'name': name,
      'systemAffected': systemAffected,
      'metadata': metadata,
    };
  }

  String get severityColor {
    switch (severity) {
      case AlertSeverity.low:
        return '#4CAF50';
      case AlertSeverity.medium:
        return '#FF9800';
      case AlertSeverity.high:
        return '#F44336';
      case AlertSeverity.critical:
        return '#9C27B0';
    }
  }

  String get severityText {
    switch (severity) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
}

class MalwareReport {
  final String? malwareType; // Dropdown: Malware Type *
  final String? infectedDeviceType; // Dropdown: Infected Device Type *
  final String? operatingSystem; // Text: Operating System
  final String? detectionMethod; // Text: How was it Detected
  final String? location; // Text: Location

  // Step 2 fields
  final String? fileName; // File upload (store file name or path)
  final String? name; // Text: Name
  final String? systemAffected; // Text: System Affected
  final String? alertSeverityLevel; // Dropdown: Alert Severity Levels

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
}
