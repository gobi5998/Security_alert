// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fraud_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FraudReportModelAdapter extends TypeAdapter<FraudReportModel> {
  @override
  final int typeId = 1;

  @override
  FraudReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FraudReportModel(
      id: fields[0] as String?,
      reportCategoryId: fields[1] as String?,
      reportTypeId: fields[2] as String?,
      alertLevels: fields[3] as String?,
      phoneNumber: fields[4] as String?,
      email: fields[5] as String?,
      website: fields[6] as String?,
      description: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      isSynced: fields[10] as bool,
      screenshots: (fields[11] as List).cast<String>(),
      documents: (fields[12] as List).cast<String>(),
      voiceMessages: (fields[13] as List).cast<String>(),
      videoUpload: (fields[14] as List).cast<String>(),
      name: fields[15] as String?,
      keycloakUserId: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FraudReportModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.reportCategoryId)
      ..writeByte(2)
      ..write(obj.reportTypeId)
      ..writeByte(3)
      ..write(obj.alertLevels)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.website)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.screenshots)
      ..writeByte(12)
      ..write(obj.documents)
      ..writeByte(13)
      ..write(obj.voiceMessages)
      ..writeByte(14)
      ..write(obj.videoUpload)
      ..writeByte(15)
      ..write(obj.name)
      ..writeByte(16)
      ..write(obj.keycloakUserId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FraudReportModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
