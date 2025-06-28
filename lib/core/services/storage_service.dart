import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _imagePicker = ImagePicker();

  // Upload image from gallery
  static Future<String?> uploadImageFromGallery(String path) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image == null) return null;
      
      if (kIsWeb) {
        // Handle web platform
        final bytes = await image.readAsBytes();
        return await uploadBytes(bytes, path);
      } else {
        // Handle mobile platform
        return await uploadFile(File(image.path), path);
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Upload image from camera
  static Future<String?> uploadImageFromCamera(String path) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image == null) return null;
      
      if (kIsWeb) {
        // Handle web platform
        final bytes = await image.readAsBytes();
        return await uploadBytes(bytes, path);
      } else {
        // Handle mobile platform
        return await uploadFile(File(image.path), path);
      }
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // Upload any file
  static Future<String?> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Upload bytes (for web)
  static Future<String?> uploadBytes(Uint8List bytes, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading bytes: $e');
      return null;
    }
  }

  // Pick and upload any file
  static Future<String?> pickAndUploadFile(String path) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) return null;
      
      final file = result.files.first;
      if (file.bytes != null) {
        return await uploadBytes(file.bytes!, path);
      } else if (file.path != null && !kIsWeb) {
        return await uploadFile(File(file.path!), path);
      } else if (kIsWeb) {
        // For web, we need to handle file differently
        print('File upload not fully supported on web yet');
        return null;
      }
      
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  // Delete file
  static Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get file size
  static Future<int?> getFileSize(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      final metadata = await ref.getMetadata();
      return metadata.size;
    } catch (e) {
      print('Error getting file size: $e');
      return null;
    }
  }

  // Generate unique file path
  static String generateFilePath(String folder, String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    return '$folder/${timestamp}_$fileName';
  }
} 