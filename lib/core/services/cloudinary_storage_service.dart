import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

class CloudinaryStorageService {
  static CloudinaryPublic? _cloudinary;
  static final ImagePicker _imagePicker = ImagePicker();

  // Initialize with your Cloudinary credentials
  static void initialize() {
    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );
  }

  static CloudinaryPublic get _instance {
    if (_cloudinary == null) {
      initialize();
    }
    return _cloudinary!;
  }

  // Upload image from gallery with progress callback
  static Future<String?> uploadImageFromGallery(
    String folder, {
    Function(double)? onProgress,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      
      if (kIsWeb) {
        return await _uploadWebFile(image, folder, 'image', onProgress: onProgress);
      } else {
        return await _uploadMobileFile(File(image.path), folder, 'image', onProgress: onProgress);
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Upload image from camera with progress callback
  static Future<String?> uploadImageFromCamera(
    String folder, {
    Function(double)? onProgress,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return null;
      
      if (kIsWeb) {
        return await _uploadWebFile(image, folder, 'image', onProgress: onProgress);
      } else {
        return await _uploadMobileFile(File(image.path), folder, 'image', onProgress: onProgress);
      }
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // Upload any file with progress callback
  static Future<String?> uploadFile(
    File file, 
    String folder, 
    String resourceType, {
    Function(double)? onProgress,
  }) async {
    try {
      if (kIsWeb) {
        // Convert File to XFile for web compatibility
        final xFile = XFile(file.path);
        return await _uploadWebFile(xFile, folder, resourceType, onProgress: onProgress);
      } else {
        return await _uploadMobileFile(file, folder, resourceType, onProgress: onProgress);
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Upload bytes (for web) with progress callback
  static Future<String?> uploadBytes(
    Uint8List bytes, 
    String folder, 
    String resourceType, {
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      if (kIsWeb) {
        return await _uploadWebBytes(bytes, folder, resourceType, fileName: fileName, onProgress: onProgress);
      } else {
        // For mobile, save bytes to temporary file first
        final tempDir = await Directory.systemTemp.createTemp('upload');
        final tempFile = File('${tempDir.path}/${fileName ?? 'upload'}');
        await tempFile.writeAsBytes(bytes);
        
        final result = await _uploadMobileFile(tempFile, folder, resourceType, onProgress: onProgress);
        
        // Clean up temp file
        await tempFile.delete();
        await tempDir.delete();
        
        return result;
      }
    } catch (e) {
      print('Error uploading bytes: $e');
      return null;
    }
  }

  // Pick and upload any file with progress callback
  static Future<String?> pickAndUploadFile(
    String folder, {
    Function(double)? onProgress,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb, // Include file data for web
      );
      
      if (result == null || result.files.isEmpty) return null;
      
      final file = result.files.first;
      final resourceType = _getResourceType(file.extension ?? '');
      
      if (kIsWeb && file.bytes != null) {
        return await _uploadWebBytes(
          file.bytes!, 
          folder, 
          resourceType, 
          fileName: file.name,
          onProgress: onProgress,
        );
      } else if (!kIsWeb && file.path != null) {
        return await _uploadMobileFile(
          File(file.path!), 
          folder, 
          resourceType,
          onProgress: onProgress,
        );
      }
      
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  // Private method for mobile file upload
  static Future<String?> _uploadMobileFile(
    File file, 
    String folder, 
    String resourceType, {
    Function(double)? onProgress,
  }) async {
    try {
      final response = await _instance.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: _getCloudinaryResourceType(resourceType),
          folder: folder,
          publicId: _generatePublicId(folder, file.path.split('/').last),
        ),
      );
      
      onProgress?.call(1.0); // Upload complete
      return response.secureUrl;
    } catch (e) {
      print('Error uploading mobile file: $e');
      return null;
    }
  }

  // Private method for web file upload
  static Future<String?> _uploadWebFile(
    XFile file, 
    String folder, 
    String resourceType, {
    Function(double)? onProgress,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.name;
      
      return await _uploadWebBytes(bytes, folder, resourceType, fileName: fileName, onProgress: onProgress);
    } catch (e) {
      print('Error uploading web file: $e');
      return null;
    }
  }

  // Private method for web bytes upload
  static Future<String?> _uploadWebBytes(
    Uint8List bytes, 
    String folder, 
    String resourceType, {
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      // Create form data for web upload
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/$resourceType/upload'
      );
      
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['folder'] = folder
        ..fields['public_id'] = _generatePublicId(folder, fileName ?? 'web_upload');
      
      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName ?? 'upload',
      );
      request.files.add(multipartFile);
      
      // Send request with progress tracking
      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        final response = await streamedResponse.stream.bytesToString();
        final jsonResponse = json.decode(response);
        
        onProgress?.call(1.0); // Upload complete
        return jsonResponse['secure_url'] as String?;
      } else {
        print('Upload failed with status: ${streamedResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading web bytes: $e');
      return null;
    }
  }

  // Get resource type based on file extension
  static String _getResourceType(String extension) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    final videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'];
    final audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'flac'];
    
    final ext = extension.toLowerCase();
    if (imageExtensions.contains(ext)) {
      return 'image';
    } else if (videoExtensions.contains(ext)) {
      return 'video';
    } else if (audioExtensions.contains(ext)) {
      return 'video'; // Cloudinary treats audio as video
    } else {
      return 'raw';
    }
  }

  // Convert resource type to Cloudinary resource type
  static CloudinaryResourceType _getCloudinaryResourceType(String resourceType) {
    switch (resourceType) {
      case 'image':
        return CloudinaryResourceType.Image;
      case 'video':
        return CloudinaryResourceType.Video;
      case 'raw':
      default:
        return CloudinaryResourceType.Raw;
    }
  }

  // Generate unique public ID for Cloudinary
  static String _generatePublicId(String folder, String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nameWithoutExtension = fileName.split('.').first;
    final extension = fileName.split('.').last;
    return '$folder/${nameWithoutExtension}_$timestamp.$extension';
  }

  // Delete file (requires Cloudinary Admin API)
  static Future<bool> deleteFile(String url) async {
    try {
      // Extract public ID from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 3) return false;
      
      final publicId = pathSegments.sublist(2).join('/').replaceAll('.${pathSegments.last.split('.').last}', '');
      
      // Use Admin API to delete (requires API key and secret)
      final deleteUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/resources/image/upload'
      );
      
      final response = await http.delete(
        deleteUrl.replace(queryParameters: {'public_ids[]': publicId}),
        headers: {
          'Authorization': 'Basic ${base64Encode(
            utf8.encode('${CloudinaryConfig.apiKey}:${CloudinaryConfig.apiSecret}')
          )}',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get file size from URL
  static Future<int?> getFileSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        return int.tryParse(response.headers['content-length'] ?? '0');
      }
      return null;
    } catch (e) {
      print('Error getting file size: $e');
      return null;
    }
  }

  // Validate file before upload
  static bool isValidFile(String fileName, int fileSize) {
    final maxSize = 10 * 1024 * 1024; // 10MB limit
    final allowedExtensions = [
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg',
      'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv',
      'mp3', 'wav', 'ogg', 'aac', 'flac',
      'pdf', 'doc', 'docx', 'txt', 'zip', 'rar'
    ];
    
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension) && fileSize <= maxSize;
  }

  // Get upload progress (simplified version)
  static void simulateProgress(Function(double) onProgress) {
    double progress = 0.0;
    const duration = Duration(milliseconds: 100);
    
    Future.doWhile(() async {
      await Future.delayed(duration);
      progress += 0.1;
      onProgress(progress.clamp(0.0, 1.0));
      return progress < 1.0;
    });
  }
} 