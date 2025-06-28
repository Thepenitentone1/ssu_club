import 'package:flutter/material.dart';

/// Comprehensive Navigation Service
/// Ensures clear, consistent, and intuitive navigation throughout the app
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Navigation state tracking
  final List<String> _navigationHistory = [];
  final Map<String, int> _pageVisitCount = {};
  final Map<String, DateTime> _lastVisitTime = {};

  // Navigation analytics
  int _totalNavigations = 0;
  double _averageNavigationTime = 0.0;
  final List<double> _navigationTimes = [];

  /// Get navigator key for global navigation
  GlobalKey<NavigatorState> get navigator => navigatorKey;

  /// Navigate to a new page with tracking
  Future<T?> navigateTo<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool clearStack = false,
    bool replace = false,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Track navigation
      _trackNavigation(routeName);
      
      // Perform navigation
      final result = await navigatorKey.currentState!.pushNamed<T>(
        routeName,
        arguments: arguments,
      );
      
      // Calculate navigation time
      final endTime = DateTime.now();
      final navigationTime = endTime.difference(startTime).inMilliseconds.toDouble();
      _navigationTimes.add(navigationTime);
      _updateAverageNavigationTime();
      
      return result;
    } catch (e) {
      debugPrint('Navigation error: $e');
      return null;
    }
  }

  /// Navigate and replace current page
  Future<T?> navigateAndReplace<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    return navigateTo<T>(
      routeName,
      arguments: arguments,
      replace: true,
    );
  }

  /// Navigate and clear stack
  Future<T?> navigateAndClearStack<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    return navigateTo<T>(
      routeName,
      arguments: arguments,
      clearStack: true,
    );
  }

  /// Go back with tracking
  void goBack<T extends Object?>([T? result]) {
    if (canGoBack()) {
      navigatorKey.currentState!.pop<T>(result);
      _removeLastNavigation();
    }
  }

  /// Check if can go back
  bool canGoBack() {
    return navigatorKey.currentState!.canPop();
  }

  /// Go back to specific route
  void goBackTo(String routeName) {
    while (canGoBack() && _navigationHistory.isNotEmpty) {
      final currentRoute = _navigationHistory.last;
      if (currentRoute == routeName) {
        break;
      }
      goBack();
    }
  }

  /// Track navigation
  void _trackNavigation(String routeName) {
    _navigationHistory.add(routeName);
    _pageVisitCount[routeName] = (_pageVisitCount[routeName] ?? 0) + 1;
    _lastVisitTime[routeName] = DateTime.now();
    _totalNavigations++;
  }

  /// Remove last navigation from history
  void _removeLastNavigation() {
    if (_navigationHistory.isNotEmpty) {
      _navigationHistory.removeLast();
    }
  }

  /// Update average navigation time
  void _updateAverageNavigationTime() {
    if (_navigationTimes.isNotEmpty) {
      _averageNavigationTime = _navigationTimes.reduce((a, b) => a + b) / _navigationTimes.length;
    }
  }

  /// Get navigation history
  List<String> get navigationHistory => List.from(_navigationHistory);

  /// Get page visit count
  Map<String, int> get pageVisitCount => Map.from(_pageVisitCount);

  /// Get last visit time for a page
  DateTime? getLastVisitTime(String routeName) {
    return _lastVisitTime[routeName];
  }

  /// Get total navigations
  int get totalNavigations => _totalNavigations;

  /// Get average navigation time
  double get averageNavigationTime => _averageNavigationTime;

  /// Get navigation analytics
  Map<String, dynamic> getNavigationAnalytics() {
    return {
      'totalNavigations': _totalNavigations,
      'averageNavigationTime': _averageNavigationTime,
      'pageVisitCount': _pageVisitCount,
      'navigationHistory': _navigationHistory,
      'lastVisitTimes': _lastVisitTime.map((key, value) => MapEntry(key, value.toIso8601String())),
    };
  }

  /// Clear navigation history
  void clearNavigationHistory() {
    _navigationHistory.clear();
    _pageVisitCount.clear();
    _lastVisitTime.clear();
    _totalNavigations = 0;
    _navigationTimes.clear();
    _averageNavigationTime = 0.0;
  }

  /// Get current route
  String? getCurrentRoute() {
    return _navigationHistory.isNotEmpty ? _navigationHistory.last : null;
  }

  /// Check if user is on specific route
  bool isOnRoute(String routeName) {
    return getCurrentRoute() == routeName;
  }

  /// Get navigation depth
  int get navigationDepth => _navigationHistory.length;

  /// Check if navigation is deep
  bool get isDeepNavigation => _navigationHistory.length > 3;

  /// Get breadcrumb navigation
  List<String> getBreadcrumbNavigation() {
    return List.from(_navigationHistory);
  }

  /// Validate navigation flow
  bool validateNavigationFlow() {
    // Check for circular navigation
    final uniqueRoutes = _navigationHistory.toSet();
    if (uniqueRoutes.length < _navigationHistory.length * 0.8) {
      return false; // Too much circular navigation
    }

    // Check for reasonable navigation depth
    if (_navigationHistory.length > 10) {
      return false; // Navigation too deep
    }

    return true;
  }

  /// Get navigation recommendations
  List<String> getNavigationRecommendations() {
    final recommendations = <String>[];

    // Check for deep navigation
    if (isDeepNavigation) {
      recommendations.add('Consider adding a "Home" or "Back to Main" option');
    }

    // Check for frequently visited pages
    final frequentPages = _pageVisitCount.entries
        .where((entry) => entry.value > 5)
        .map((entry) => entry.key)
        .toList();

    if (frequentPages.isNotEmpty) {
      recommendations.add('Consider adding quick access to: ${frequentPages.join(', ')}');
    }

    // Check for slow navigation
    if (_averageNavigationTime > 1000) {
      recommendations.add('Navigation is slow, consider optimizing page transitions');
    }

    return recommendations;
  }

  /// Get navigation performance metrics
  Map<String, dynamic> getNavigationPerformanceMetrics() {
    return {
      'totalNavigations': _totalNavigations,
      'averageNavigationTime': _averageNavigationTime,
      'navigationDepth': navigationDepth,
      'isDeepNavigation': isDeepNavigation,
      'uniqueRoutesVisited': _pageVisitCount.length,
      'mostVisitedPage': _getMostVisitedPage(),
      'leastVisitedPage': _getLeastVisitedPage(),
      'navigationFlowValid': validateNavigationFlow(),
      'recommendations': getNavigationRecommendations(),
    };
  }

  /// Get most visited page
  String? _getMostVisitedPage() {
    if (_pageVisitCount.isEmpty) return null;
    
    return _pageVisitCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get least visited page
  String? _getLeastVisitedPage() {
    if (_pageVisitCount.isEmpty) return null;
    
    return _pageVisitCount.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// Reset navigation metrics
  void resetNavigationMetrics() {
    _totalNavigations = 0;
    _navigationTimes.clear();
    _averageNavigationTime = 0.0;
  }

  /// Get navigation efficiency score (0-100)
  double getNavigationEfficiencyScore() {
    double score = 100.0;

    // Penalize deep navigation
    if (isDeepNavigation) {
      score -= 20.0;
    }

    // Penalize slow navigation
    if (_averageNavigationTime > 1000) {
      score -= 30.0;
    }

    // Penalize circular navigation
    if (!validateNavigationFlow()) {
      score -= 25.0;
    }

    // Bonus for efficient navigation
    if (_averageNavigationTime < 500 && !isDeepNavigation) {
      score += 10.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Get navigation insights
  Map<String, dynamic> getNavigationInsights() {
    return {
      'efficiencyScore': getNavigationEfficiencyScore(),
      'performanceMetrics': getNavigationPerformanceMetrics(),
      'analytics': getNavigationAnalytics(),
      'recommendations': getNavigationRecommendations(),
      'isOptimal': getNavigationEfficiencyScore() >= 80.0,
    };
  }
} 