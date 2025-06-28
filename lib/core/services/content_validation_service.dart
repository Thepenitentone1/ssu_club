import '../constants/app_constants.dart';

/// Comprehensive Content Validation Service
/// Ensures all app requirements are met and content is accurate and well-organized
class ContentValidationService {
  static final ContentValidationService _instance = ContentValidationService._internal();
  factory ContentValidationService() => _instance;
  ContentValidationService._internal();

  // Content validation state
  final Map<String, bool> _requirementStatus = {};
  final Map<String, String> _validationMessages = {};

  /// Initialize content validation
  void initialize() {
    _validateAllRequirements();
  }

  /// Validate all requirements
  void _validateAllRequirements() {
    // Validate feature requirements
    for (final requirement in AppConstants.featureRequirements.keys) {
      _requirementStatus[requirement] = AppConstants.featureRequirements[requirement] ?? false;
    }

    // Validate content categories
    _validateContentCategories();
    
    // Validate performance requirements
    _validatePerformanceRequirements();
    
    // Validate accessibility requirements
    _validateAccessibilityRequirements();
    
    // Validate UI constants
    _validateUIConstants();
  }

  /// Validate content categories
  void _validateContentCategories() {
    // Validate club categories
    if (AppConstants.clubCategories.isNotEmpty) {
      _requirementStatus['Club Categories'] = true;
      _validationMessages['Club Categories'] = '${AppConstants.clubCategories.length} categories defined';
    } else {
      _requirementStatus['Club Categories'] = false;
      _validationMessages['Club Categories'] = 'No club categories defined';
    }

    // Validate event categories
    if (AppConstants.eventCategories.isNotEmpty) {
      _requirementStatus['Event Categories'] = true;
      _validationMessages['Event Categories'] = '${AppConstants.eventCategories.length} categories defined';
    } else {
      _requirementStatus['Event Categories'] = false;
      _validationMessages['Event Categories'] = 'No event categories defined';
    }

    // Validate announcement categories
    if (AppConstants.announcementCategories.isNotEmpty) {
      _requirementStatus['Announcement Categories'] = true;
      _validationMessages['Announcement Categories'] = '${AppConstants.announcementCategories.length} categories defined';
    } else {
      _requirementStatus['Announcement Categories'] = false;
      _validationMessages['Announcement Categories'] = 'No announcement categories defined';
    }
  }

  /// Validate performance requirements
  void _validatePerformanceRequirements() {
    // Validate load time requirement
    if (AppConstants.maxLoadTimeMs <= 500) {
      _requirementStatus['Performance Load Time'] = true;
      _validationMessages['Performance Load Time'] = 'Load time target: ${AppConstants.maxLoadTimeMs}ms';
    } else {
      _requirementStatus['Performance Load Time'] = false;
      _validationMessages['Performance Load Time'] = 'Load time target too high: ${AppConstants.maxLoadTimeMs}ms';
    }

    // Validate memory usage requirement
    if (AppConstants.maxMemoryUsageMb <= 100) {
      _requirementStatus['Performance Memory Usage'] = true;
      _validationMessages['Performance Memory Usage'] = 'Memory usage target: ${AppConstants.maxMemoryUsageMb}MB';
    } else {
      _requirementStatus['Performance Memory Usage'] = false;
      _validationMessages['Performance Memory Usage'] = 'Memory usage target too high: ${AppConstants.maxMemoryUsageMb}MB';
    }

    // Validate frame rate requirement
    if (AppConstants.minFrameRate >= 60.0) {
      _requirementStatus['Performance Frame Rate'] = true;
      _validationMessages['Performance Frame Rate'] = 'Frame rate target: ${AppConstants.minFrameRate}fps';
    } else {
      _requirementStatus['Performance Frame Rate'] = false;
      _validationMessages['Performance Frame Rate'] = 'Frame rate target too low: ${AppConstants.minFrameRate}fps';
    }
  }

  /// Validate accessibility requirements
  void _validateAccessibilityRequirements() {
    // Validate contrast ratio requirement
    if (AppConstants.minContrastRatio >= 4.5) {
      _requirementStatus['Accessibility Contrast Ratio'] = true;
      _validationMessages['Accessibility Contrast Ratio'] = 'Contrast ratio: ${AppConstants.minContrastRatio}:1';
    } else {
      _requirementStatus['Accessibility Contrast Ratio'] = false;
      _validationMessages['Accessibility Contrast Ratio'] = 'Contrast ratio too low: ${AppConstants.minContrastRatio}:1';
    }

    // Validate touch target size requirement
    if (AppConstants.minTouchTargetSize >= 44.0) {
      _requirementStatus['Accessibility Touch Targets'] = true;
      _validationMessages['Accessibility Touch Targets'] = 'Touch target size: ${AppConstants.minTouchTargetSize}px';
    } else {
      _requirementStatus['Accessibility Touch Targets'] = false;
      _validationMessages['Accessibility Touch Targets'] = 'Touch target size too small: ${AppConstants.minTouchTargetSize}px';
    }

    // Validate font size requirement
    if (AppConstants.minFontSize >= 16.0) {
      _requirementStatus['Accessibility Font Size'] = true;
      _validationMessages['Accessibility Font Size'] = 'Font size: ${AppConstants.minFontSize}px';
    } else {
      _requirementStatus['Accessibility Font Size'] = false;
      _validationMessages['Accessibility Font Size'] = 'Font size too small: ${AppConstants.minFontSize}px';
    }
  }

  /// Validate UI constants
  void _validateUIConstants() {
    // Validate padding constants
    if (AppConstants.defaultPadding > 0) {
      _requirementStatus['UI Padding Constants'] = true;
      _validationMessages['UI Padding Constants'] = 'Default padding: ${AppConstants.defaultPadding}px';
    } else {
      _requirementStatus['UI Padding Constants'] = false;
      _validationMessages['UI Padding Constants'] = 'Invalid padding value';
    }

    // Validate radius constants
    if (AppConstants.defaultRadius > 0) {
      _requirementStatus['UI Radius Constants'] = true;
      _validationMessages['UI Radius Constants'] = 'Default radius: ${AppConstants.defaultRadius}px';
    } else {
      _requirementStatus['UI Radius Constants'] = false;
      _validationMessages['UI Radius Constants'] = 'Invalid radius value';
    }

    // Validate animation duration constants
    if (AppConstants.defaultAnimationDuration.inMilliseconds > 0) {
      _requirementStatus['UI Animation Constants'] = true;
      _validationMessages['UI Animation Constants'] = 'Animation duration: ${AppConstants.defaultAnimationDuration.inMilliseconds}ms';
    } else {
      _requirementStatus['UI Animation Constants'] = false;
      _validationMessages['UI Animation Constants'] = 'Invalid animation duration';
    }
  }

  /// Validate content requirements
  bool validateContentRequirements() {
    return AppConstants.validateContentRequirements();
  }

  /// Validate performance requirements
  bool validatePerformanceRequirements({
    required int loadTime,
    required int memoryUsage,
    required double frameRate,
  }) {
    return AppConstants.validatePerformanceRequirements(
      loadTime: loadTime,
      memoryUsage: memoryUsage,
      frameRate: frameRate,
    );
  }

  /// Validate accessibility requirements
  bool validateAccessibilityRequirements({
    required double contrastRatio,
    required double touchTargetSize,
    required double fontSize,
  }) {
    return AppConstants.validateAccessibilityRequirements(
      contrastRatio: contrastRatio,
      touchTargetSize: touchTargetSize,
      fontSize: fontSize,
    );
  }

  /// Get requirement status
  bool getRequirementStatus(String requirement) {
    return _requirementStatus[requirement] ?? false;
  }

  /// Get validation message
  String getValidationMessage(String requirement) {
    return _validationMessages[requirement] ?? 'No validation message available';
  }

  /// Get all requirement statuses
  Map<String, bool> getAllRequirementStatuses() {
    return Map.from(_requirementStatus);
  }

  /// Get all validation messages
  Map<String, String> getAllValidationMessages() {
    return Map.from(_validationMessages);
  }

  /// Get content validation report
  Map<String, dynamic> getContentValidationReport() {
    final allRequirements = <String, bool>{};
    allRequirements.addAll(AppConstants.featureRequirements);
    allRequirements.addAll(_requirementStatus);

    final passedRequirements = allRequirements.values.where((status) => status).length;
    final totalRequirements = allRequirements.length;
    final passRate = totalRequirements > 0 ? (passedRequirements / totalRequirements) * 100 : 0;

    return {
      'totalRequirements': totalRequirements,
      'passedRequirements': passedRequirements,
      'failedRequirements': totalRequirements - passedRequirements,
      'passRate': passRate,
      'allRequirements': allRequirements,
      'validationMessages': _validationMessages,
      'contentRequirementsValidated': validateContentRequirements(),
      'appName': AppConstants.appName,
      'appVersion': AppConstants.appVersion,
      'appDescription': AppConstants.appDescription,
    };
  }

  /// Check if all requirements are met
  bool areAllRequirementsMet() {
    final allRequirements = <String, bool>{};
    allRequirements.addAll(AppConstants.featureRequirements);
    allRequirements.addAll(_requirementStatus);

    return allRequirements.values.every((status) => status);
  }

  /// Get failed requirements
  List<String> getFailedRequirements() {
    final allRequirements = <String, bool>{};
    allRequirements.addAll(AppConstants.featureRequirements);
    allRequirements.addAll(_requirementStatus);

    return allRequirements.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get passed requirements
  List<String> getPassedRequirements() {
    final allRequirements = <String, bool>{};
    allRequirements.addAll(AppConstants.featureRequirements);
    allRequirements.addAll(_requirementStatus);

    return allRequirements.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
} 