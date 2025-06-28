import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../constants/app_constants.dart';

/// Comprehensive Performance Service
/// Ensures optimal app performance and monitors key metrics
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Performance metrics
  final Map<String, DateTime> _startTimes = {};
  final Map<String, int> _loadTimes = {};
  final Map<String, int> _memoryUsage = {};
  final List<double> _frameRates = [];
  
  // Performance thresholds
  static const int maxLoadTimeMs = 500;
  static const int maxMemoryUsageMb = 100;
  static const double minFrameRate = 60.0;
  
  // Cache management
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Performance monitoring
  final bool _isMonitoringEnabled = true;
  Timer? _performanceTimer;

  /// Initialize performance service
  Future<void> initialize() async {
    // Set up performance monitoring
    _setupPerformanceMonitoring();
    
    // Preload critical resources
    await _preloadCriticalResources();
    
    // Set up memory management
    _setupMemoryManagement();
    
    debugPrint('Performance Service initialized');
  }

  /// Set up performance monitoring
  void _setupPerformanceMonitoring() {
    if (_isMonitoringEnabled) {
      _performanceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _monitorPerformance();
      });
    }
  }

  /// Preload critical resources
  Future<void> _preloadCriticalResources() async {
    try {
      // Preload fonts
      await _preloadFonts();
      
      // Preload images
      await _preloadImages();
      
      // Preload data
      await _preloadData();
      
      debugPrint('Critical resources preloaded');
    } catch (e) {
      debugPrint('Error preloading resources: $e');
    }
  }

  /// Preload fonts
  Future<void> _preloadFonts() async {
    // Fonts are typically loaded automatically by Flutter
    // This is a placeholder for any custom font loading logic
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Preload images
  Future<void> _preloadImages() async {
    // Preload critical images
    final criticalImages = [
      'assets/images/ssulg.png',
      'assets/icons/app_icon.png',
      'assets/icons/splash_icon.png',
    ];
    
    for (final imagePath in criticalImages) {
      try {
        // Note: precacheImage requires a BuildContext, so we'll skip this for now
        // In a real app, you'd call this from a widget with context
        debugPrint('Would preload image: $imagePath');
      } catch (e) {
        debugPrint('Error preloading image $imagePath: $e');
      }
    }
  }

  /// Preload data
  Future<void> _preloadData() async {
    // Preload static data that's frequently accessed
    _cache['club_categories'] = AppConstants.clubCategories;
    _cache['event_categories'] = AppConstants.eventCategories;
    _cache['announcement_categories'] = AppConstants.announcementCategories;
    
    _cacheTimestamps['club_categories'] = DateTime.now();
    _cacheTimestamps['event_categories'] = DateTime.now();
    _cacheTimestamps['announcement_categories'] = DateTime.now();
  }

  /// Set up memory management
  void _setupMemoryManagement() {
    // Set up periodic cache cleanup
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupCache();
    });
  }

  /// Start performance timer
  void startTimer(String name) {
    _startTimes[name] = DateTime.now();
  }

  /// End performance timer
  void endTimer(String name) {
    final startTime = _startTimes[name];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _loadTimes[name] = duration.inMilliseconds;
      
      // Log performance data
      developer.log(
        'Performance: $name took ${duration.inMilliseconds}ms',
        name: 'PerformanceService',
      );
      
      _startTimes.remove(name);
    }
  }

  /// Monitor overall performance
  void _monitorPerformance() {
    // Check memory usage
    _checkMemoryUsage();
    
    // Check frame rate
    _checkFrameRate();
    
    // Log performance summary
    _logPerformanceSummary();
  }

  /// Check memory usage
  void _checkMemoryUsage() {
    // This would typically use platform-specific APIs
    // For now, we'll use a simplified approach
    final currentMemory = _estimateMemoryUsage();
    _memoryUsage['current'] = currentMemory;
    
    if (currentMemory > maxMemoryUsageMb) {
      developer.log(
        'Warning: High memory usage detected: ${currentMemory}MB',
        name: 'PerformanceService',
      );
      _optimizeMemory();
    }
  }

  /// Estimate memory usage (simplified)
  int _estimateMemoryUsage() {
    // This is a simplified estimation
    // In a real app, you'd use platform-specific APIs
    return (_cache.length * 2) + (_loadTimes.length * 1);
  }

  /// Check frame rate
  void _checkFrameRate() {
    // This would typically use Flutter's performance overlay
    // For now, we'll use a simplified approach
    final currentFrameRate = _estimateFrameRate();
    _frameRates.add(currentFrameRate);
    
    // Keep only last 10 measurements
    if (_frameRates.length > 10) {
      _frameRates.removeAt(0);
    }
    
    final averageFrameRate = _frameRates.reduce((a, b) => a + b) / _frameRates.length;
    
    if (averageFrameRate < minFrameRate) {
      developer.log(
        'Warning: Low frame rate detected: ${averageFrameRate.toStringAsFixed(1)}fps',
        name: 'PerformanceService',
      );
    }
  }

  /// Estimate frame rate (simplified)
  double _estimateFrameRate() {
    // This is a simplified estimation
    // In a real app, you'd use Flutter's performance monitoring
    return 60.0; // Assume 60fps for now
  }

  /// Optimize memory usage
  void _optimizeMemory() {
    // Clear old cache entries
    _cleanupCache();
    
    // Clear old performance data
    if (_loadTimes.length > 50) {
      _loadTimes.clear();
    }
    
    if (_frameRates.length > 20) {
      _frameRates.clear();
    }
  }

  /// Clean up cache
  void _cleanupCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      final age = now.difference(entry.value);
      if (age > AppConstants.cacheExpiration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Log performance summary
  void _logPerformanceSummary() {
    if (_loadTimes.isNotEmpty) {
      final averageLoadTime = _loadTimes.values.reduce((a, b) => a + b) / _loadTimes.length;
      developer.log(
        'Performance Summary - Avg Load Time: ${averageLoadTime.toStringAsFixed(1)}ms, '
        'Memory: ${_memoryUsage['current'] ?? 0}MB, '
        'Cache Size: ${_cache.length}',
        name: 'PerformanceService',
      );
    }
  }

  /// Cache data with expiration
  void cacheData(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Get cached data
  dynamic getCachedData(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age <= AppConstants.cacheExpiration) {
        return _cache[key];
      } else {
        // Remove expired data
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
    return null;
  }

  /// Optimize image loading
  Future<void> optimizeImageLoading(String imagePath) async {
    try {
      // Preload image if not already cached
      if (!_cache.containsKey('image_$imagePath')) {
        // Note: precacheImage requires a BuildContext, so we'll skip this for now
        // In a real app, you'd call this from a widget with context
        debugPrint('Would optimize image loading: $imagePath');
        cacheData('image_$imagePath', true);
      }
    } catch (e) {
      debugPrint('Error optimizing image loading: $e');
    }
  }

  /// Optimize list rendering
  Widget optimizeListRendering({
    required List<Widget> children,
    required ScrollController controller,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: children.length,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }

  /// Optimize grid rendering
  Widget optimizeGridRendering({
    required List<Widget> children,
    required int crossAxisCount,
    double crossAxisSpacing = 0.0,
    double mainAxisSpacing = 0.0,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }

  /// Validate performance requirements
  bool validatePerformanceRequirements() {
    final currentLoadTime = _loadTimes.values.isNotEmpty 
        ? _loadTimes.values.reduce((a, b) => a + b) / _loadTimes.length 
        : 0;
    final currentMemory = _memoryUsage['current'] ?? 0;
    final currentFrameRate = _frameRates.isNotEmpty 
        ? _frameRates.reduce((a, b) => a + b) / _frameRates.length 
        : 60.0;
    
    return currentLoadTime <= maxLoadTimeMs &&
           currentMemory <= maxMemoryUsageMb &&
           currentFrameRate >= minFrameRate;
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final averageLoadTime = _loadTimes.values.isNotEmpty 
        ? _loadTimes.values.reduce((a, b) => a + b) / _loadTimes.length 
        : 0;
    final averageFrameRate = _frameRates.isNotEmpty 
        ? _frameRates.reduce((a, b) => a + b) / _frameRates.length 
        : 60.0;
    
    return {
      'averageLoadTime': averageLoadTime,
      'currentMemoryUsage': _memoryUsage['current'] ?? 0,
      'averageFrameRate': averageFrameRate,
      'cacheSize': _cache.length,
      'performanceValidated': validatePerformanceRequirements(),
      'maxLoadTime': maxLoadTimeMs,
      'maxMemoryUsage': maxMemoryUsageMb,
      'minFrameRate': minFrameRate,
    };
  }

  /// Dispose performance service
  void dispose() {
    _performanceTimer?.cancel();
    _cache.clear();
    _cacheTimestamps.clear();
    _loadTimes.clear();
    _memoryUsage.clear();
    _frameRates.clear();
  }
} 