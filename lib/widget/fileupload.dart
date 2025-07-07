import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class FileUploadWidget extends StatefulWidget {
  final Function(List<FileData>) onFilesSelected;

  const FileUploadWidget({Key? key, required this.onFilesSelected})
    : super(key: key);

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final List<FileData> selectedFiles = [];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage();
    for (var image in images) {
      selectedFiles.add(
        FileData(file: image, type: FileType.image, name: image.name),
      );
    }
    widget.onFilesSelected(selectedFiles);
    setState(() {});
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (result != null) {
      for (var file in result.files) {
        selectedFiles.add(
          FileData(file: file, type: FileType.document, name: file.name),
        );
      }
      widget.onFilesSelected(selectedFiles);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.add),
          title: Text('Add Screenshots'),
          subtitle: Text(
            'limit: ${selectedFiles.where((f) => f.type == FileType.image).length}/5',
          ),
          onTap: _pickImages,
        ),
        ListTile(
          leading: Icon(Icons.add),
          title: Text('Add Documents'),
          subtitle: Text('limit: 5mb'),
          onTap: _pickDocuments,
        ),
        // Display selected files
        if (selectedFiles.isNotEmpty)
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedFiles.length,
              itemBuilder: (context, index) {
                final file = selectedFiles[index];
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Icon(_getFileIcon(file.type)),
                        Text(file.name, maxLines: 1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getFileIcon(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image;
      case FileType.document:
        return Icons.description;
    }
  }
}

enum FileType { image, document }

class FileData {
  final dynamic file;
  final FileType type;
  final String name;

  FileData({required this.file, required this.type, required this.name});
}
