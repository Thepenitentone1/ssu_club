import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import '../constants/app_constants.dart';

/// Media Info Model
class MediaInfo {
  final String id;
  final String path;
  final String type;
  final int fileSize;
  final String format;
  final double qualityScore;
  final bool isOptimized;
  final DateTime lastAccessed;
  final int accessCount;

  MediaInfo({
    required this.id,
    required this.path,
    required this.type,
    required this.fileSize,
    required this.format,
    required this.qualityScore,
    required this.isOptimized,
    required this.lastAccessed,
    required this.accessCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'type': type,
      'fileSize': fileSize,
      'format': format,
      'qualityScore': qualityScore,
      'isOptimized': isOptimized,
      'lastAccessed': lastAccessed.toIso8601String(),
      'accessCount': accessCount,
    };
  }

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      id: json['id'],
      path: json['path'],
      type: json['type'],
      fileSize: json['fileSize'],
      format: json['format'],
      qualityScore: json['qualityScore'],
      isOptimized: json['isOptimized'],
      lastAccessed: DateTime.parse(json['lastAccessed']),
      accessCount: json['accessCount'],
    );
  }
}

/// Media Error Model
class MediaError {
  final String mediaId;
  final String errorType;
  final String message;
  final DateTime timestamp;

  MediaError({
    required this.mediaId,
    required this.errorType,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'MediaError(mediaId: $mediaId, errorType: $errorType, message: $message, timestamp: $timestamp)';
  }
}

/// Comprehensive Graphics & Media Service
/// Ensures high quality, relevant, and optimized media handling
class GraphicsMediaService {
  static final GraphicsMediaService _instance = GraphicsMediaService._internal();
  factory GraphicsMediaService() => _instance;
  GraphicsMediaService._internal();

  // Media tracking
  final Map<String, MediaInfo> _mediaRegistry = {};
  final List<String> _supportedFormats = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
  final Map<String, int> _mediaUsageCount = {};
  final Map<String, double> _mediaQualityScores = {};

  // Performance tracking
  final Map<String, double> _loadTimes = {};
  final Map<String, int> _fileSizes = {};
  final Map<String, bool> _optimizationStatus = {};

  // Error tracking
  final List<MediaError> _mediaErrors = [];
  int _totalMediaErrors = 0;

  /// Initialize media service
  void initialize() {
    _loadMediaRegistry();
    _validateSupportedFormats();
  }

  /// Load media registry
  void _loadMediaRegistry() {
    // Load existing media from assets and storage
    _loadAssetMedia();
    _loadStorageMedia();
  }

  /// Load asset media
  void _loadAssetMedia() {
    final assetPaths = [
      'assets/images/ssulg.png',
      'assets/images/clubs/delta.png',
      'assets/images/clubs/educators.png',
      'assets/images/clubs/elem.png',
      'assets/images/clubs/eng.png',
      'assets/images/clubs/kaupod.png',
      'assets/images/clubs/math.png',
      'assets/images/clubs/ministry.png',
      'assets/images/clubs/pschy.png',
      'assets/images/clubs/redcross.png',
      'assets/images/clubs/system.png',
      'assets/images/clubs/united.png',
    ];

    for (final path in assetPaths) {
      _registerMedia(path, 'asset', 'image');
    }
  }

  /// Load storage media
  void _loadStorageMedia() {
    // This would load media from Firebase Storage or local storage
    // Implementation depends on storage service
  }

  /// Register media
  void _registerMedia(String path, String type, String format) {
    final id = _generateMediaId(path);
    
    if (!_mediaRegistry.containsKey(id)) {
      _mediaRegistry[id] = MediaInfo(
        id: id,
        path: path,
        type: type,
        fileSize: 0, // Will be updated when loaded
        format: format,
        qualityScore: 100.0, // Default high quality
        isOptimized: true, // Assume optimized
        lastAccessed: DateTime.now(),
        accessCount: 0,
      );
    }
  }

  /// Generate media ID
  String _generateMediaId(String path) {
    return path.replaceAll('/', '_').replaceAll('.', '_');
  }

  /// Validate supported formats
  void _validateSupportedFormats() {
    for (final format in _supportedFormats) {
      if (!AppConstants.supportedImageFormats.contains(format)) {
        debugPrint('Warning: Format $format not in AppConstants supported formats');
      }
    }
  }

  /// Check if format is supported
  bool isFormatSupported(String format) {
    return _supportedFormats.contains(format.toLowerCase());
  }

  /// Validate media file
  Future<bool> validateMediaFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _trackMediaError(path, 'file_not_found', 'Media file does not exist');
        return false;
      }

      final fileSize = await file.length();
      if (fileSize > AppConstants.maxImageSizeMb * 1024 * 1024) {
        _trackMediaError(path, 'file_too_large', 'File size exceeds maximum allowed');
        return false;
      }

      final extension = path.split('.').last.toLowerCase();
      if (!isFormatSupported(extension)) {
        _trackMediaError(path, 'unsupported_format', 'File format not supported');
        return false;
      }

      return true;
    } catch (e) {
      _trackMediaError(path, 'validation_error', e.toString());
      return false;
    }
  }

  /// Optimize image
  Future<File?> optimizeImage(File imageFile) async {
    try {
      final path = imageFile.path;
      final extension = path.split('.').last.toLowerCase();
      
      // Check if already optimized
      if (_isImageOptimized(imageFile)) {
        return imageFile;
      }

      // Basic optimization (in a real app, you'd use image processing libraries)
      final optimizedPath = path.replaceAll('.$extension', '_optimized.$extension');
      final optimizedFile = await imageFile.copy(optimizedPath);
      
      _markAsOptimized(optimizedPath);
      return optimizedFile;
    } catch (e) {
      _trackMediaError(imageFile.path, 'optimization_error', e.toString());
      return null;
    }
  }

  /// Check if image is optimized
  bool _isImageOptimized(File imageFile) {
    return _optimizationStatus[imageFile.path] ?? false;
  }

  /// Mark as optimized
  void _markAsOptimized(String path) {
    _optimizationStatus[path] = true;
  }

  /// Load media with tracking
  Future<Uint8List?> loadMedia(String path) async {
    final startTime = DateTime.now();
    
    try {
      // Validate file
      if (!await validateMediaFile(path)) {
        return null;
      }

      // Load file
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      // Track load time
      final endTime = DateTime.now();
      final loadTime = endTime.difference(startTime).inMilliseconds.toDouble();
      _loadTimes[path] = loadTime;
      
      // Track usage
      _trackMediaUsage(path);
      
      // Update file size
      _fileSizes[path] = bytes.length;
      
      return bytes;
    } catch (e) {
      _trackMediaError(path, 'load_error', e.toString());
      return null;
    }
  }

  /// Track media usage
  void _trackMediaUsage(String path) {
    final id = _generateMediaId(path);
    _mediaUsageCount[path] = (_mediaUsageCount[path] ?? 0) + 1;
    
    if (_mediaRegistry.containsKey(id)) {
      final info = _mediaRegistry[id]!;
      _mediaRegistry[id] = MediaInfo(
        id: info.id,
        path: info.path,
        type: info.type,
        fileSize: info.fileSize,
        format: info.format,
        qualityScore: info.qualityScore,
        isOptimized: info.isOptimized,
        lastAccessed: DateTime.now(),
        accessCount: info.accessCount + 1,
      );
    }
  }

  /// Track media error
  void _trackMediaError(String mediaId, String errorType, String message) {
    _mediaErrors.add(MediaError(
      mediaId: mediaId,
      errorType: errorType,
      message: message,
      timestamp: DateTime.now(),
    ));
    _totalMediaErrors++;
  }

  /// Get media quality score
  double getMediaQualityScore(String path) {
    return _mediaQualityScores[path] ?? 100.0;
  }

  /// Set media quality score
  void setMediaQualityScore(String path, double score) {
    _mediaQualityScores[path] = score.clamp(0.0, 100.0);
  }

  /// Get media load time
  double getMediaLoadTime(String path) {
    return _loadTimes[path] ?? 0.0;
  }

  /// Get media file size
  int getMediaFileSize(String path) {
    return _fileSizes[path] ?? 0;
  }

  /// Check if media is optimized
  bool isMediaOptimized(String path) {
    return _optimizationStatus[path] ?? false;
  }

  /// Get media registry
  Map<String, MediaInfo> get mediaRegistry => Map.from(_mediaRegistry);

  /// Get media usage count
  Map<String, int> get mediaUsageCount => Map.from(_mediaUsageCount);

  /// Get media quality scores
  Map<String, double> get mediaQualityScores => Map.from(_mediaQualityScores);

  /// Get load times
  Map<String, double> get loadTimes => Map.from(_loadTimes);

  /// Get file sizes
  Map<String, int> get fileSizes => Map.from(_fileSizes);

  /// Get optimization status
  Map<String, bool> get optimizationStatus => Map.from(_optimizationStatus);

  /// Get media errors
  List<MediaError> get mediaErrors => List.from(_mediaErrors);

  /// Get total media errors
  int get totalMediaErrors => _totalMediaErrors;

  /// Get media performance metrics
  Map<String, dynamic> getMediaPerformanceMetrics() {
    final avgLoadTime = _loadTimes.values.isEmpty 
        ? 0.0 
        : _loadTimes.values.reduce((a, b) => a + b) / _loadTimes.length;
    
    final avgFileSize = _fileSizes.values.isEmpty 
        ? 0 
        : _fileSizes.values.reduce((a, b) => a + b) ~/ _fileSizes.length;
    
    final avgQualityScore = _mediaQualityScores.values.isEmpty 
        ? 100.0 
        : _mediaQualityScores.values.reduce((a, b) => a + b) / _mediaQualityScores.length;
    
    final optimizedCount = _optimizationStatus.values.where((optimized) => optimized).length;
    final totalMedia = _optimizationStatus.length;
    final optimizationRate = totalMedia > 0 ? (optimizedCount / totalMedia) * 100 : 100.0;

    return {
      'averageLoadTime': avgLoadTime,
      'averageFileSize': avgFileSize,
      'averageQualityScore': avgQualityScore,
      'optimizationRate': optimizationRate,
      'totalMedia': totalMedia,
      'optimizedMedia': optimizedCount,
      'totalErrors': _totalMediaErrors,
      'errorRate': totalMedia > 0 ? (_totalMediaErrors / totalMedia) * 100 : 0.0,
    };
  }

  /// Get most used media
  List<String> getMostUsedMedia({int limit = 10}) {
    final sortedMedia = _mediaUsageCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMedia.take(limit).map((entry) => entry.key).toList();
  }

  /// Get slowest loading media
  List<String> getSlowestLoadingMedia({int limit = 10}) {
    final sortedMedia = _loadTimes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMedia.take(limit).map((entry) => entry.key).toList();
  }

  /// Get largest media files
  List<String> getLargestMediaFiles({int limit = 10}) {
    final sortedMedia = _fileSizes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMedia.take(limit).map((entry) => entry.key).toList();
  }

  /// Get unoptimized media
  List<String> getUnoptimizedMedia() {
    return _optimizationStatus.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get media recommendations
  List<String> getMediaRecommendations() {
    final recommendations = <String>[];

    // Check for unoptimized media
    final unoptimized = getUnoptimizedMedia();
    if (unoptimized.isNotEmpty) {
      recommendations.add('Optimize ${unoptimized.length} media files for better performance');
    }

    // Check for large files
    final largeFiles = getLargestMediaFiles(limit: 5);
    if (largeFiles.isNotEmpty) {
      recommendations.add('Consider compressing large files: ${largeFiles.join(', ')}');
    }

    // Check for slow loading media
    final slowMedia = getSlowestLoadingMedia(limit: 5);
    if (slowMedia.isNotEmpty) {
      recommendations.add('Optimize loading for slow media: ${slowMedia.join(', ')}');
    }

    // Check error rate
    final errorRate = _mediaRegistry.isNotEmpty ? (_totalMediaErrors / _mediaRegistry.length) * 100 : 0.0;
    if (errorRate > 5.0) {
      recommendations.add('High media error rate: ${errorRate.toStringAsFixed(1)}%. Review media files.');
    }

    return recommendations;
  }

  /// Validate media quality
  bool validateMediaQuality() {
    // Check if all media meets quality standards
    final lowQualityMedia = _mediaQualityScores.entries
        .where((entry) => entry.value < 80.0)
        .map((entry) => entry.key)
        .toList();

    return lowQualityMedia.isEmpty;
  }

  /// Get media health score (0-100)
  double getMediaHealthScore() {
    double score = 100.0;

    // Check optimization rate
    final optimizationRate = _optimizationStatus.isNotEmpty 
        ? _optimizationStatus.values.where((optimized) => optimized).length / _optimizationStatus.length
        : 1.0;
    score *= optimizationRate;

    // Check error rate
    final errorRate = _mediaRegistry.isNotEmpty ? _totalMediaErrors / _mediaRegistry.length : 0.0;
    score -= errorRate * 50;

    // Check quality scores
    final avgQuality = _mediaQualityScores.values.isEmpty 
        ? 100.0 
        : _mediaQualityScores.values.reduce((a, b) => a + b) / _mediaQualityScores.length;
    score = score * 0.7 + avgQuality * 0.3;

    // Check load times
    final avgLoadTime = _loadTimes.values.isEmpty 
        ? 0.0 
        : _loadTimes.values.reduce((a, b) => a + b) / _loadTimes.length;
    if (avgLoadTime > 1000) {
      score -= 20;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Get comprehensive media insights
  Map<String, dynamic> getMediaInsights() {
    return {
      'healthScore': getMediaHealthScore(),
      'isHealthy': getMediaHealthScore() >= 90.0,
      'performanceMetrics': getMediaPerformanceMetrics(),
      'mostUsedMedia': getMostUsedMedia(),
      'slowestLoadingMedia': getSlowestLoadingMedia(),
      'largestMediaFiles': getLargestMediaFiles(),
      'unoptimizedMedia': getUnoptimizedMedia(),
      'recommendations': getMediaRecommendations(),
      'qualityValidated': validateMediaQuality(),
      'totalMedia': _mediaRegistry.length,
      'supportedFormats': _supportedFormats,
    };
  }

  /// Clear media cache
  void clearMediaCache() {
    _loadTimes.clear();
    _mediaUsageCount.clear();
    _mediaQualityScores.clear();
  }

  /// Reset media tracking
  void resetMediaTracking() {
    _mediaErrors.clear();
    _totalMediaErrors = 0;
    clearMediaCache();
  }
} 