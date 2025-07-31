import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileUploadService {
  static final Dio _dio = Dio();
  static const String baseUrl = 'https://740fb54b271e.ngrok-free.app';

  // Get MIME type for file
  static String _getMimeType(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  // File upload response model
  static Map<String, dynamic> _createFileData(Map<String, dynamic> response) {
    print('🔍 Creating file data from response: $response');
    
    // Ensure all required fields are present with proper fallbacks
    final fileData = {
      'uploadPath': response['url'] ?? '',
      's3Url': response['url'] ?? '',
      's3Key': response['fileId'] ?? '',
      'originalName': response['fileName'] ?? '',
      'fileId': response['fileId'] ?? '',
      'url': response['url'] ?? '',
      'key': response['key'] ?? response['fileId'] ?? '', // Use key from response, fallback to fileId
      'fileName': response['fileName'] ?? '',
      'size': response['size'] ?? 0,
      'contentType': response['contentType'] ?? '',
    };
    
    print('🔍 Created file data: $fileData');
    return fileData;
  }

  // Upload single file
  static Future<Map<String, dynamic>?> uploadFile(
      File file,
      String reportId,
      String fileType, {
        Function(int, int)? onProgress,
      }) async {
    try {


      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print('🔑 Token present: ${token != null}');
      if (token != null) {
        print('🔑 Token preview: ${token.substring(0, 20)}...');
      }

      // Validate file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      // Validate file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }

      // Create FormData with proper field name and MIME type
      String fileName = file.path.split('/').last;
      String mimeType = _getMimeType(fileName);

      print('📄 File name: $fileName');
      print('📄 MIME type: $mimeType');

      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      // Add reportId as a field if needed
      formData.fields.add(MapEntry('reportId', reportId));
      formData.fields.add(MapEntry('fileType', fileType));

      final uploadUrl = '$baseUrl/file-upload/threads-$fileType?reportId=$reportId';


      // Upload with progress tracking
      var response = await _dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            print('📊 Response status: $status');
            return status! < 500; // Accept all status codes < 500
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        onSendProgress: (sent, total) {
          print('📤 Upload progress: $sent/$total bytes');
          onProgress?.call(sent, total);
        },
      );



      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Upload response received: ${response.data}');
        final fileData = _createFileData(response.data);
        print('✅ File upload successful: $fileData');
        return fileData;
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.data}');
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.data}',
        );
      }
    } catch (e) {
      print('❌ Error uploading file: $e');
      if (e is DioException) {

      }
      return null;
    }
  }

  // Upload multiple files
  static Future<List<Map<String, dynamic>>> uploadFiles(
      List<File> files,
      String reportId,
      String fileType, {
        Function(int, int)? onProgress,
      }) async {
    print('📦 Starting upload of ${files.length} files');
    List<Map<String, dynamic>> uploadedFiles = [];

    for (int i = 0; i < files.length; i++) {
      File file = files[i];
      print('📤 Uploading file ${i + 1}/${files.length}: ${file.path}');

      // Calculate progress for multiple files
      Function(int, int)? progressCallback;
      if (onProgress != null) {
        progressCallback = (sent, total) {
          int overallProgress =
              ((i * 100) + (sent * 100 / total)) ~/ files.length;
          onProgress(overallProgress, 100);
        };
      }

      var result = await uploadFile(
        file,
        reportId,
        fileType,
        onProgress: progressCallback,
      );
      if (result != null) {
        uploadedFiles.add(result);
        print('✅ File ${i + 1} uploaded successfully');
      } else {
        print('❌ File ${i + 1} upload failed');
      }
    }

    print('📦 Upload complete. Successfully uploaded: ${uploadedFiles.length}/${files.length} files');
    return uploadedFiles;
  }

  // Categorize files by type and return structured response
  static Map<String, dynamic> categorizeFilesAndCreateResponse(
      List<Map<String, dynamic>> uploadedFiles,
      ) {
    print('📂 Categorizing ${uploadedFiles.length} uploaded files');

    List<Map<String, dynamic>> screenshots = [];
    List<Map<String, dynamic>> documents = [];
    List<Map<String, dynamic>> voiceMessages = [];

    for (var file in uploadedFiles) {
      String fileName = file['fileName']?.toString().toLowerCase() ?? '';
      String contentType = file['contentType']?.toString().toLowerCase() ?? '';

      print('📄 Processing file: $fileName (type: $contentType)');
      print('📄 File data: $file');

      // Check if it's an image
      if (fileName.endsWith('.png') ||
          fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.gif') ||
          fileName.endsWith('.bmp') ||
          fileName.endsWith('.webp') ||
          contentType.startsWith('image/')) {
        screenshots.add(file);
        print('🖼️  Categorized as screenshot');
      }
      // Check if it's an audio file
      else if (fileName.endsWith('.mp3') ||
          fileName.endsWith('.wav') ||
          fileName.endsWith('.m4a') ||
          contentType.startsWith('audio/')) {
        voiceMessages.add(file);
        print('🎵 Categorized as voice message');
      }
      // Check if it's a document
      else if (fileName.endsWith('.pdf') ||
          fileName.endsWith('.doc') ||
          fileName.endsWith('.docx') ||
          fileName.endsWith('.txt') ||
          contentType == 'application/pdf' ||
          contentType.startsWith('application/vnd.openxmlformats') ||
          contentType == 'application/msword' ||
          contentType == 'text/plain') {
        documents.add(file);
        print('📄 Categorized as document');
      } else {
        print('❓ Unknown file type, adding to documents');
        documents.add(file);
      }
    }

    // Return in the exact format expected by backend
    final result = {
      'screenshots': screenshots,
      'voiceMessages': voiceMessages,
      'documents': documents,
    };

    print('📂 Categorization complete:');
    print('  📸 Screenshots: ${screenshots.length}');
    print('  🎵 Voice Messages: ${voiceMessages.length}');
    print('  📄 Documents: ${documents.length}');

    return result;
  }

  // Upload files and return categorized response for backend storage
  static Future<Map<String, dynamic>> uploadFilesAndCategorize(
      List<File> files,
      String reportId,
      String fileType, {
        Function(int, int)? onProgress,
      }) async {


    List<Map<String, dynamic>> uploadedFiles = await uploadFiles(
      files,
      reportId,
      fileType,
      onProgress: onProgress,
    );

    final categorizedFiles = categorizeFilesAndCreateResponse(uploadedFiles);
    print('✅ Upload and categorize process complete');
    return categorizedFiles;
  }

  // Helper method to get file URLs for backend submission
  static Map<String, List<String>> extractFileUrls(Map<String, dynamic> categorizedFiles) {
    List<String> screenshotUrls = (categorizedFiles['screenshots'] as List)
        .map((file) => file['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    List<String> voiceMessageUrls = (categorizedFiles['voiceMessages'] as List)
        .map((file) => file['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    List<String> documentUrls = (categorizedFiles['documents'] as List)
        .map((file) => file['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return {
      'screenshots': screenshotUrls,
      'voiceMessages': voiceMessageUrls,
      'documents': documentUrls,
    };
  }

  // Helper method to create complete report data for backend submission
  static Map<String, dynamic> createReportData({
    required Map<String, dynamic> formData,
    required Map<String, dynamic> fileData,
  }) {
    print('🔍 Creating complete report data:');
    print('  Form data: $formData');
    print('  File data: $fileData');
    
    // Ensure file arrays are properly structured
    List<Map<String, dynamic>> screenshots = [];
    List<Map<String, dynamic>> voiceMessages = [];
    List<Map<String, dynamic>> documents = [];
    
    if (fileData['screenshots'] != null) {
      screenshots = (fileData['screenshots'] as List).cast<Map<String, dynamic>>();
    }
    if (fileData['voiceMessages'] != null) {
      voiceMessages = (fileData['voiceMessages'] as List).cast<Map<String, dynamic>>();
    }
    if (fileData['documents'] != null) {
      documents = (fileData['documents'] as List).cast<Map<String, dynamic>>();
    }
    
    final result = {
      ...formData,
      'screenshots': screenshots,
      'voiceMessages': voiceMessages,
      'documents': documents,
    };
    
    print('🔍 Complete report data created:');
    print('  Screenshots: ${screenshots.length}');
    print('  Voice Messages: ${voiceMessages.length}');
    print('  Documents: ${documents.length}');
    
    return result;
  }

  // Helper method to get complete file objects for backend storage
  static Map<String, List<Map<String, dynamic>>> extractFileObjects(Map<String, dynamic> categorizedFiles) {
    List<Map<String, dynamic>> screenshots = (categorizedFiles['screenshots'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> voiceMessages = (categorizedFiles['voiceMessages'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> documents = (categorizedFiles['documents'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return {
      'screenshots': screenshots,
      'voiceMessages': voiceMessages,
      'documents': documents,
    };
  }
}

class FileUploadWidget extends StatefulWidget {
  final String reportId;
  final String fileType; // scam, fraud, or malware
  final Function(Map<String, dynamic>) onFilesUploaded; // Updated callback
  final bool autoUpload;

  const FileUploadWidget({
    Key? key,
    required this.reportId,
    required this.fileType,
    required this.onFilesUploaded,
    this.autoUpload = false,
  }) : super(key: key);

  @override
  State<FileUploadWidget> createState() => FileUploadWidgetState();
}

class FileUploadWidgetState extends State<FileUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  List<File> selectedImages = [];
  List<File> selectedDocuments = [];
  List<File> selectedVoiceFiles = [];

  bool isUploading = false;
  int uploadProgress = 0;
  String uploadStatus = '';
  
  // Store uploaded files
  Map<String, dynamic> _uploadedFiles = {
    'screenshots': [],
    'voiceMessages': [],
    'documents': [],
  };

  // Method to get current uploaded files without triggering upload
  Map<String, dynamic> getCurrentUploadedFiles() {
    return _uploadedFiles;
  }

  // Method to trigger upload from outside
  Future<Map<String, dynamic>> triggerUpload() async {
    print('🎯 Trigger upload called');
    print('📁 Selected images: ${selectedImages.length}');
    print('📁 Selected documents: ${selectedDocuments.length}');
    print('📁 Selected voice files: ${selectedVoiceFiles.length}');

    if (selectedImages.isEmpty &&
        selectedDocuments.isEmpty &&
        selectedVoiceFiles.isEmpty) {
      print('⚠️  No files selected for upload');
      return {
        'screenshots': [],
        'voiceMessages': [],
        'documents': [],
      };
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0;
      uploadStatus = 'Preparing files...';
    });

    try {
      // Upload all files with the same fileType
      if (selectedImages.isNotEmpty ||
          selectedDocuments.isNotEmpty ||
          selectedVoiceFiles.isNotEmpty) {
        setState(() => uploadStatus = 'Uploading files...');

        List<File> allFiles = [];
        allFiles.addAll(selectedImages);
        allFiles.addAll(selectedDocuments);
        allFiles.addAll(selectedVoiceFiles);

        print('📤 Starting upload of ${allFiles.length} files');
        print('📋 Report ID: ${widget.reportId}');
        print('📋 File Type: ${widget.fileType}');

        var categorizedFiles = await FileUploadService.uploadFilesAndCategorize(
          allFiles,
          widget.reportId,
          widget.fileType, // Use the fileType passed from parent
          onProgress: (sent, total) {
            setState(() => uploadProgress = sent);
            print('📤 Upload progress: $sent/$total');
          },
        );

        setState(() {
          isUploading = false;
          uploadStatus = 'Upload completed!';
        });

        print('✅ Upload completed successfully');
        print('📊 Categorized files: $categorizedFiles');

        // Store uploaded files
        _uploadedFiles = categorizedFiles;

        // Notify parent widget with categorized files
        widget.onFilesUploaded(categorizedFiles);

        return categorizedFiles;
      }

      setState(() {
        isUploading = false;
        uploadStatus = 'No files to upload';
      });

      print('⚠️  No files to upload');
      return {
        'screenshots': [],
        'voiceMessages': [],
        'documents': [],
      };
    } catch (e) {
      print('❌ Error in triggerUpload: $e');
      setState(() {
        isUploading = false;
        uploadStatus = 'Upload failed';
      });

      String errorMessage = 'Upload failed';
      if (e.toString().contains('400')) {
        errorMessage = 'Bad request - check file format and size';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Authentication required';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Upload endpoint not found';
      } else if (e.toString().contains('413')) {
        errorMessage = 'File too large';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error - try again later';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      return {
        'screenshots': [],
        'voiceMessages': [],
        'documents': [],
      };
    }
  }

  // Pick images
  Future<void> _pickImages() async {
    print('📸 Picking images...');
    final images = await _picker.pickMultiImage();
    if (images != null) {
      print('📸 Selected ${images.length} images');
      setState(() {
        selectedImages.addAll(images.map((e) => File(e.path)));
      });
      print('📸 Total images selected: ${selectedImages.length}');
    } else {
      print('📸 No images selected');
    }
  }

  // Pick documents
  Future<void> _pickDocuments() async {
    print('📄 Picking documents...');
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      print('📄 Selected ${result.files.length} documents');
      setState(() {
        selectedDocuments.addAll(result.paths.map((e) => File(e!)));
      });
      print('📄 Total documents selected: ${selectedDocuments.length}');
    } else {
      print('📄 No documents selected');
    }
  }

  // Pick voice files
  Future<void> _pickVoiceFiles() async {
    print('🎵 Picking voice files...');
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result != null) {
      print('🎵 Selected ${result.files.length} voice files');
      setState(() {
        selectedVoiceFiles.addAll(result.paths.map((e) => File(e!)));
      });
      print('🎵 Total voice files selected: ${selectedVoiceFiles.length}');
    } else {
      print('🎵 No voice files selected');
    }
  }

  // Remove file from list
  void _removeFile(List<File> fileList, int index) {
    setState(() {
      fileList.removeAt(index);
    });
  }

  // Upload all files
  Future<void> _uploadAllFiles() async {
    if (selectedImages.isEmpty &&
        selectedDocuments.isEmpty &&
        selectedVoiceFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file to upload'),
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0;
      uploadStatus = 'Preparing files...';
    });

    try {
      // Upload all files with the same fileType
      if (selectedImages.isNotEmpty ||
          selectedDocuments.isNotEmpty ||
          selectedVoiceFiles.isNotEmpty) {
        setState(() => uploadStatus = 'Uploading files...');

        List<File> allFiles = [];
        allFiles.addAll(selectedImages);
        allFiles.addAll(selectedDocuments);
        allFiles.addAll(selectedVoiceFiles);

        var categorizedFiles = await FileUploadService.uploadFilesAndCategorize(
          allFiles,
          widget.reportId,
          widget.fileType, // Use the fileType passed from parent
          onProgress: (sent, total) {
            setState(() => uploadProgress = sent);
          },
        );

        setState(() {
          isUploading = false;
          uploadStatus = 'Upload completed!';
        });

        // Store uploaded files
        _uploadedFiles = categorizedFiles;

        // Notify parent widget with categorized files
        widget.onFilesUploaded(categorizedFiles);

        // Show success message with file counts
        int totalFiles = (categorizedFiles['screenshots'] as List).length +
            (categorizedFiles['voiceMessages'] as List).length +
            (categorizedFiles['documents'] as List).length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully uploaded $totalFiles files',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUploading = false;
        uploadStatus = 'Upload failed';
      });

      String errorMessage = 'Upload failed';
      if (e.toString().contains('400')) {
        errorMessage = 'Bad request - check file format and size';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Authentication required';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Upload endpoint not found';
      } else if (e.toString().contains('413')) {
        errorMessage = 'File too large';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error - try again later';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Images
        ListTile(
          leading: Image.asset(
            'assets/image/document.png', // your local image path
            width: 30,
            height: 30,
          ),
          title: const Text('Add Images'),
          subtitle: Text('Selected: ${selectedImages.length}'),
          onTap: _pickImages,
        ),

        // Documents
        ListTile(
          leading: Image.asset(
            'assets/image/document.png', // your local image path
            width: 30,
            height: 30,
          ),
          title: const Text('Add Documents'),
          subtitle: Text('Selected: ${selectedDocuments.length}'),
          onTap: _pickDocuments,
        ),

        // Voice Files
        ListTile(
          leading: Image.asset(
            'assets/image/document.png', // your local image path
            width: 30,
            height: 30,
          ),
          title: const Text('Add Voice Files'),
          subtitle: Text('Selected: ${selectedVoiceFiles.length}'),
          onTap: _pickVoiceFiles,
        ),

        // Show upload button only if not in auto upload mode
        if (!widget.autoUpload) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isUploading ? null : _uploadAllFiles,
            child: Text(isUploading ? 'Uploading...' : 'Upload Files'),
          ),
        ],
      ],
    );
  }
}