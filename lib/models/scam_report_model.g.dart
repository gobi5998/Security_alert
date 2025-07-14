// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scam_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScamReportModelAdapter extends TypeAdapter<ScamReportModel> {
  @override
  final int typeId = 1;

  @override
  ScamReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScamReportModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as String,
      severity: fields[4] as String,
      date: fields[5] as DateTime,
      isSynced: fields[6] as bool,
      screenshotPaths: (fields[7] as List).cast<String>(),
      documentPaths: (fields[8] as List).cast<String>(),
      voicePaths: (fields[12] as List).cast<String>(),
      phone: fields[9] as String?,
      email: fields[10] as String?,
      website: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScamReportModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.severity)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.isSynced)
      ..writeByte(7)
      ..write(obj.screenshotPaths)
      ..writeByte(8)
      ..write(obj.documentPaths)
      ..writeByte(9)
      ..write(obj.phone)
      ..writeByte(10)
      ..write(obj.email)
      ..writeByte(11)
      ..write(obj.website)
      ..writeByte(12)
      ..write(obj.voicePaths);
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
