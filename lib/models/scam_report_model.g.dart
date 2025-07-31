// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scam_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScamReportModelAdapter extends TypeAdapter<ScamReportModel> {
  @override
  final int typeId = 0;

  @override
  ScamReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScamReportModel(
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
      isSynced: fields[10] as bool?,
      screenshots: (fields[11] as List).cast<String>(),
      documents: (fields[12] as List).cast<String>(),
      voiceMessages: (fields[15] as List).cast<String>(),
      videoUpload: (fields[16] as List).cast<String>(),
      name: fields[13] as String?,
      keycloakUserId: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScamReportModel obj) {
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
      ..write(obj.name)
      ..writeByte(14)
      ..write(obj.keycloakUserId)
      ..writeByte(15)
      ..write(obj.voiceMessages)
      ..writeByte(16)
      ..write(obj.videoUpload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScamReportModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
