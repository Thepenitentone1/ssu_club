import '../constants/app_constants.dart';

/// Comprehensive Functionality Service
/// Ensures all features work flawlessly with proper error handling and user feedback
class FunctionalityService {
  static final FunctionalityService _instance = FunctionalityService._internal();
  factory FunctionalityService() => _instance;
  FunctionalityService._internal();

  // Functionality tracking
  final Map<String, bool> _featureStatus = {};
  final Map<String, int> _featureUsageCount = {};
  final Map<String, List<String>> _featureErrors = {};
  final Map<String, double> _featurePerformance = {};

  // User interaction tracking
  final Map<String, int> _interactionCount = {};
  final Map<String, double> _interactionSuccessRate = {};
  final List<String> _recentInteractions = [];

  // Error tracking
  final List<FunctionalityError> _errors = [];
  int _totalErrors = 0;
  int _resolvedErrors = 0;

  /// Initialize functionality tracking
  void initialize() {
    _initializeFeatureStatus();
    _initializeInteractionTracking();
  }

  /// Initialize feature status
  void _initializeFeatureStatus() {
    for (final feature in AppConstants.featureRequirements.keys) {
      _featureStatus[feature] = true; // Assume all features are working
      _featureUsageCount[feature] = 0;
      _featureErrors[feature] = [];
      _featurePerformance[feature] = 0.0;
    }
  }

  /// Initialize interaction tracking
  void _initializeInteractionTracking() {
    final interactions = [
      'button_press',
      'form_submit',
      'image_upload',
      'navigation',
      'search',
      'filter',
      'chat_message',
      'notification',
      'profile_update',
      'event_registration',
    ];

    for (final interaction in interactions) {
      _interactionCount[interaction] = 0;
      _interactionSuccessRate[interaction] = 100.0;
    }
  }

  /// Track feature usage
  void trackFeatureUsage(String featureName) {
    if (_featureUsageCount.containsKey(featureName)) {
      _featureUsageCount[featureName] = (_featureUsageCount[featureName] ?? 0) + 1;
    }
  }

  /// Track feature performance
  void trackFeaturePerformance(String featureName, double performanceScore) {
    if (_featurePerformance.containsKey(featureName)) {
      _featurePerformance[featureName] = performanceScore;
    }
  }

  /// Track feature error
  void trackFeatureError(String featureName, String errorMessage) {
    if (_featureErrors.containsKey(featureName)) {
      _featureErrors[featureName]!.add(errorMessage);
      _totalErrors++;
      
      _errors.add(FunctionalityError(
        feature: featureName,
        message: errorMessage,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Track user interaction
  void trackInteraction(String interactionType, {bool success = true}) {
    _interactionCount[interactionType] = (_interactionCount[interactionType] ?? 0) + 1;
    _recentInteractions.add(interactionType);
    
    // Keep only last 100 interactions
    if (_recentInteractions.length > 100) {
      _recentInteractions.removeAt(0);
    }

    // Update success rate
    if (_interactionSuccessRate.containsKey(interactionType)) {
      final currentRate = _interactionSuccessRate[interactionType]!;
      final totalInteractions = _interactionCount[interactionType]!;
      
      if (success) {
        _interactionSuccessRate[interactionType] = 
            ((currentRate * (totalInteractions - 1)) + 100) / totalInteractions;
      } else {
        _interactionSuccessRate[interactionType] = 
            (currentRate * (totalInteractions - 1)) / totalInteractions;
      }
    }
  }

  /// Mark feature as working
  void markFeatureWorking(String featureName) {
    _featureStatus[featureName] = true;
  }

  /// Mark feature as broken
  void markFeatureBroken(String featureName) {
    _featureStatus[featureName] = false;
  }

  /// Check if feature is working
  bool isFeatureWorking(String featureName) {
    return _featureStatus[featureName] ?? false;
  }

  /// Get feature status
  Map<String, bool> get featureStatus => Map.from(_featureStatus);

  /// Get feature usage count
  Map<String, int> get featureUsageCount => Map.from(_featureUsageCount);

  /// Get feature errors
  Map<String, List<String>> get featureErrors => Map.from(_featureErrors);

  /// Get feature performance
  Map<String, double> get featurePerformance => Map.from(_featurePerformance);

  /// Get interaction count
  Map<String, int> get interactionCount => Map.from(_interactionCount);

  /// Get interaction success rate
  Map<String, double> get interactionSuccessRate => Map.from(_interactionSuccessRate);

  /// Get recent interactions
  List<String> get recentInteractions => List.from(_recentInteractions);

  /// Get all errors
  List<FunctionalityError> get errors => List.from(_errors);

  /// Get total errors
  int get totalErrors => _totalErrors;

  /// Get resolved errors
  int get resolvedErrors => _resolvedErrors;

  /// Resolve error
  void resolveError(String featureName, String errorMessage) {
    final error = _errors.firstWhere(
      (e) => e.feature == featureName && e.message == errorMessage,
      orElse: () => FunctionalityError(
        feature: featureName,
        message: errorMessage,
        timestamp: DateTime.now(),
      ),
    );

    if (_errors.contains(error)) {
      _errors.remove(error);
      _resolvedErrors++;
      
      // Remove from feature errors
      if (_featureErrors[featureName]?.contains(errorMessage) ?? false) {
        _featureErrors[featureName]!.remove(errorMessage);
      }
    }
  }

  /// Get functionality health score (0-100)
  double getFunctionalityHealthScore() {
    double score = 100.0;

    // Check feature status
    final workingFeatures = _featureStatus.values.where((status) => status).length;
    final totalFeatures = _featureStatus.length;
    
    if (totalFeatures > 0) {
      final featureHealth = (workingFeatures / totalFeatures) * 100;
      score = score * 0.6 + featureHealth * 0.4;
    }

    // Check error rate
    if (_totalErrors > 0) {
      final errorRate = (_totalErrors - _resolvedErrors) / _totalErrors;
      score -= errorRate * 30;
    }

    // Check interaction success rate
    final avgSuccessRate = _interactionSuccessRate.values.isEmpty 
        ? 100.0 
        : _interactionSuccessRate.values.reduce((a, b) => a + b) / _interactionSuccessRate.length;
    
    score = score * 0.7 + avgSuccessRate * 0.3;

    return score.clamp(0.0, 100.0);
  }

  /// Get functionality report
  Map<String, dynamic> getFunctionalityReport() {
    return {
      'healthScore': getFunctionalityHealthScore(),
      'featureStatus': _featureStatus,
      'featureUsageCount': _featureUsageCount,
      'featureErrors': _featureErrors,
      'featurePerformance': _featurePerformance,
      'interactionCount': _interactionCount,
      'interactionSuccessRate': _interactionSuccessRate,
      'recentInteractions': _recentInteractions,
      'totalErrors': _totalErrors,
      'resolvedErrors': _resolvedErrors,
      'unresolvedErrors': _totalErrors - _resolvedErrors,
      'errorRate': _totalErrors > 0 ? (_totalErrors - _resolvedErrors) / _totalErrors : 0.0,
      'isHealthy': getFunctionalityHealthScore() >= 90.0,
    };
  }

  /// Get broken features
  List<String> getBrokenFeatures() {
    return _featureStatus.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get most used features
  List<String> getMostUsedFeatures({int limit = 5}) {
    final sortedFeatures = _featureUsageCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedFeatures.take(limit).map((entry) => entry.key).toList();
  }

  /// Get least used features
  List<String> getLeastUsedFeatures({int limit = 5}) {
    final sortedFeatures = _featureUsageCount.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return sortedFeatures.take(limit).map((entry) => entry.key).toList();
  }

  /// Get features with most errors
  List<String> getFeaturesWithMostErrors({int limit = 5}) {
    final sortedFeatures = _featureErrors.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    return sortedFeatures.take(limit).map((entry) => entry.key).toList();
  }

  /// Get interaction patterns
  Map<String, dynamic> getInteractionPatterns() {
    final patterns = <String, dynamic>{};
    
    // Most common interactions
    final sortedInteractions = _interactionCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    patterns['mostCommonInteractions'] = sortedInteractions.take(5).map((entry) => {
      'type': entry.key,
      'count': entry.value,
    }).toList();

    // Success rates
    patterns['successRates'] = _interactionSuccessRate.entries.map((entry) => {
      'type': entry.key,
      'rate': entry.value,
    }).toList();

    // Recent activity
    patterns['recentActivity'] = _recentInteractions.take(10).toList();

    return patterns;
  }

  /// Validate all functionality
  bool validateAllFunctionality() {
    // Check if all features are working
    final allFeaturesWorking = _featureStatus.values.every((status) => status);
    
    // Check error rate
    final errorRate = _totalErrors > 0 ? (_totalErrors - _resolvedErrors) / _totalErrors : 0.0;
    final acceptableErrorRate = errorRate <= 0.1; // 10% or less
    
    // Check interaction success rate
    final avgSuccessRate = _interactionSuccessRate.values.isEmpty 
        ? 100.0 
        : _interactionSuccessRate.values.reduce((a, b) => a + b) / _interactionSuccessRate.length;
    final acceptableSuccessRate = avgSuccessRate >= 95.0; // 95% or higher
    
    return allFeaturesWorking && acceptableErrorRate && acceptableSuccessRate;
  }

  /// Get functionality recommendations
  List<String> getFunctionalityRecommendations() {
    final recommendations = <String>[];

    // Check broken features
    final brokenFeatures = getBrokenFeatures();
    if (brokenFeatures.isNotEmpty) {
      recommendations.add('Fix broken features: ${brokenFeatures.join(', ')}');
    }

    // Check features with most errors
    final errorProneFeatures = getFeaturesWithMostErrors(limit: 3);
    if (errorProneFeatures.isNotEmpty) {
      recommendations.add('Improve error handling for: ${errorProneFeatures.join(', ')}');
    }

    // Check low success rate interactions
    final lowSuccessInteractions = _interactionSuccessRate.entries
        .where((entry) => entry.value < 90.0)
        .map((entry) => entry.key)
        .toList();
    
    if (lowSuccessInteractions.isNotEmpty) {
      recommendations.add('Improve user experience for: ${lowSuccessInteractions.join(', ')}');
    }

    // Check unused features
    final unusedFeatures = getLeastUsedFeatures(limit: 3);
    if (unusedFeatures.isNotEmpty) {
      recommendations.add('Consider promoting or improving: ${unusedFeatures.join(', ')}');
    }

    return recommendations;
  }

  /// Reset functionality tracking
  void resetFunctionalityTracking() {
    _featureUsageCount.clear();
    _featureErrors.clear();
    _featurePerformance.clear();
    _interactionCount.clear();
    _interactionSuccessRate.clear();
    _recentInteractions.clear();
    _errors.clear();
    _totalErrors = 0;
    _resolvedErrors = 0;
    
    _initializeFeatureStatus();
    _initializeInteractionTracking();
  }

  /// Get comprehensive functionality insights
  Map<String, dynamic> getFunctionalityInsights() {
    return {
      'healthScore': getFunctionalityHealthScore(),
      'isHealthy': getFunctionalityHealthScore() >= 90.0,
      'allFeaturesWorking': validateAllFunctionality(),
      'brokenFeatures': getBrokenFeatures(),
      'mostUsedFeatures': getMostUsedFeatures(),
      'featuresWithMostErrors': getFeaturesWithMostErrors(),
      'interactionPatterns': getInteractionPatterns(),
      'recommendations': getFunctionalityRecommendations(),
      'report': getFunctionalityReport(),
    };
  }
}

/// Functionality Error Model
class FunctionalityError {
  final String feature;
  final String message;
  final DateTime timestamp;

  FunctionalityError({
    required this.feature,
    required this.message,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FunctionalityError &&
        other.feature == feature &&
        other.message == message;
  }

  @override
  int get hashCode => feature.hashCode ^ message.hashCode;

  @override
  String toString() {
    return 'FunctionalityError(feature: $feature, message: $message, timestamp: $timestamp)';
  }
} 