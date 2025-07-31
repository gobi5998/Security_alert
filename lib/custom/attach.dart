import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/FileStauts.dart';

class AttachmentUploadWidget extends StatefulWidget {
  const AttachmentUploadWidget({super.key});

  @override
  State<AttachmentUploadWidget> createState() => _AttachmentUploadWidgetState();
}

class _AttachmentUploadWidgetState extends State<AttachmentUploadWidget> {
  final List<UploadedFile> _files = [];
  final int maxFiles = 5;
  final int maxSizeMB = 10;
  bool uploading = false;

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    final picked = result.files.where((f) => f.size <= maxSizeMB * 1024 * 1024);

    if (_files.length + picked.length > maxFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 files allowed.')),
      );
      return;
    }

    for (var file in picked) {
      final uploadFile = UploadedFile(
        name: file.name,
        size: file.size,
        file: file.path != null ? File(file.path!) : null,
        status: FileStatus.uploading,
      );

      setState(() => _files.add(uploadFile));
      await uploadDocument(uploadFile);
    }
  }

  Future<void> uploadDocument(UploadedFile uploadFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(uploadFile.file!.path, filename: uploadFile.name),
      });

      final response = await Dio().post(
        'https://ad04021b0f33.ngrok-free.app', // Change to your actual API
        data: formData,
      );

      if (response.statusCode == 200) {
        setState(() {
          uploadFile.status = FileStatus.uploaded;
          uploadFile.fileId = response.data['fileId'];
          uploadFile.url = response.data['url'];
          uploadFile.contentType = response.data['contentType'];
        });
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      setState(() {
        uploadFile.status = FileStatus.failed;
      });
    }
  }

  void deleteFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  void retryUpload(UploadedFile file) {
    uploadDocument(file);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: uploading ? null : pickFiles,
          icon: const Icon(Icons.attach_file),
          label: const Text('Attach Files'),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            Icon statusIcon;

            switch (file.status) {
              case FileStatus.uploading:
                statusIcon = const Icon(Icons.upload, color: Colors.blue);
                break;
              case FileStatus.uploaded:
                statusIcon = const Icon(Icons.check_circle, color: Colors.green);
                break;
              case FileStatus.failed:
                statusIcon = const Icon(Icons.error, color: Colors.red);
                break;
            }

            return ListTile(
              leading: statusIcon,
              title: Text(file.name),
              subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (file.status == FileStatus.failed)
                    IconButton(
                      icon: const Icon(Icons.replay),
                      onPressed: () => retryUpload(file),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteFile(index),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
