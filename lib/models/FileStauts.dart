import 'dart:io';

enum FileStatus { uploading, uploaded, failed }

class UploadedFile {
  final String name;
  final int size;
  final File? file;
  FileStatus status;
  String? fileId;
  String? url;
  String? contentType;

  UploadedFile({
    required this.name,
    required this.size,
    required this.file,
    required this.status,
    this.fileId,
    this.url,
    this.contentType,
  });
}
