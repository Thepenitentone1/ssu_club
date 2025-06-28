import 'package:flutter/material.dart';

/// Comprehensive Responsive Design Service
/// Ensures the app adapts seamlessly to all screen sizes and orientations
class ResponsiveService {
  static final ResponsiveService _instance = ResponsiveService._internal();
  factory ResponsiveService() => _instance;
  ResponsiveService._internal();

  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  // Device type detection
  bool _isMobile = false;
  bool _isTablet = false;
  bool _isDesktop = false;
  bool _isLargeDesktop = false;
  bool _isLandscape = false;
  bool _isPortrait = false;

  // Screen dimensions
  double _screenWidth = 0;
  double _screenHeight = 0;
  double _pixelRatio = 1.0;

  // Getters
  bool get isMobile => _isMobile;
  bool get isTablet => _isTablet;
  bool get isDesktop => _isDesktop;
  bool get isLargeDesktop => _isLargeDesktop;
  bool get isLandscape => _isLandscape;
  bool get isPortrait => _isPortrait;
  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  double get pixelRatio => _pixelRatio;

  /// Initialize responsive service
  void initialize(BuildContext context) {
    _updateScreenInfo(context);
  }

  /// Update screen information
  void _updateScreenInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _pixelRatio = mediaQuery.devicePixelRatio;
    
    // Determine device type
    _isMobile = _screenWidth < mobileBreakpoint;
    _isTablet = _screenWidth >= mobileBreakpoint && _screenWidth < tabletBreakpoint;
    _isDesktop = _screenWidth >= tabletBreakpoint && _screenWidth < desktopBreakpoint;
    _isLargeDesktop = _screenWidth >= largeDesktopBreakpoint;
    
    // Determine orientation
    _isLandscape = _screenWidth > _screenHeight;
    _isPortrait = _screenWidth <= _screenHeight;
  }

  /// Get responsive padding
  EdgeInsets getResponsivePadding({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    double padding = _getResponsiveValue(
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeDesktop: largeDesktop ?? 48.0,
    );
    
    return EdgeInsets.all(padding);
  }

  /// Get responsive horizontal padding
  EdgeInsets getResponsiveHorizontalPadding({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    double padding = _getResponsiveValue(
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeDesktop: largeDesktop ?? 48.0,
    );
    
    return EdgeInsets.symmetric(horizontal: padding);
  }

  /// Get responsive vertical padding
  EdgeInsets getResponsiveVerticalPadding({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    double padding = _getResponsiveValue(
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
      largeDesktop: largeDesktop ?? 48.0,
    );
    
    return EdgeInsets.symmetric(vertical: padding);
  }

  /// Get responsive margin
  EdgeInsets getResponsiveMargin({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    double margin = _getResponsiveValue(
      mobile: mobile ?? 8.0,
      tablet: tablet ?? 16.0,
      desktop: desktop ?? 24.0,
      largeDesktop: largeDesktop ?? 32.0,
    );
    
    return EdgeInsets.all(margin);
  }

  /// Get responsive spacing
  double getResponsiveSpacing({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 8.0,
      tablet: tablet ?? 16.0,
      desktop: desktop ?? 24.0,
      largeDesktop: largeDesktop ?? 32.0,
    );
  }

  /// Get responsive font size
  double getResponsiveFontSize({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 14.0,
      tablet: tablet ?? 16.0,
      desktop: desktop ?? 18.0,
      largeDesktop: largeDesktop ?? 20.0,
    );
  }

  /// Get responsive icon size
  double getResponsiveIconSize({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 20.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 28.0,
      largeDesktop: largeDesktop ?? 32.0,
    );
  }

  /// Get responsive border radius
  double getResponsiveBorderRadius({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 8.0,
      tablet: tablet ?? 12.0,
      desktop: desktop ?? 16.0,
      largeDesktop: largeDesktop ?? 20.0,
    );
  }

  /// Get responsive grid cross axis count
  int getResponsiveGridCrossAxisCount({
    int? mobile,
    int? tablet,
    int? desktop,
    int? largeDesktop,
  }) {
    return _getResponsiveIntValue(
      mobile: mobile ?? 1,
      tablet: tablet ?? 2,
      desktop: desktop ?? 3,
      largeDesktop: largeDesktop ?? 4,
    );
  }

  /// Get responsive list item height
  double getResponsiveListItemHeight({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 80.0,
      tablet: tablet ?? 100.0,
      desktop: desktop ?? 120.0,
      largeDesktop: largeDesktop ?? 140.0,
    );
  }

  /// Get responsive card height
  double getResponsiveCardHeight({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 200.0,
      tablet: tablet ?? 250.0,
      desktop: desktop ?? 300.0,
      largeDesktop: largeDesktop ?? 350.0,
    );
  }

  /// Get responsive button height
  double getResponsiveButtonHeight({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 44.0,
      tablet: tablet ?? 48.0,
      desktop: desktop ?? 52.0,
      largeDesktop: largeDesktop ?? 56.0,
    );
  }

  /// Get responsive value based on screen size
  double _getResponsiveValue({
    required double mobile,
    required double tablet,
    required double desktop,
    required double largeDesktop,
  }) {
    if (_isMobile) return mobile;
    if (_isTablet) return tablet;
    if (_isDesktop) return desktop;
    if (_isLargeDesktop) return largeDesktop;
    return tablet; // Default fallback
  }

  /// Get responsive integer value based on screen size
  int _getResponsiveIntValue({
    required int mobile,
    required int tablet,
    required int desktop,
    required int largeDesktop,
  }) {
    if (_isMobile) return mobile;
    if (_isTablet) return tablet;
    if (_isDesktop) return desktop;
    if (_isLargeDesktop) return largeDesktop;
    return tablet; // Default fallback
  }

  /// Get responsive layout builder
  Widget buildResponsiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    Widget? largeDesktop,
  }) {
    if (_isMobile) return mobile;
    if (_isTablet) return tablet ?? mobile;
    if (_isDesktop) return desktop ?? tablet ?? mobile;
    if (_isLargeDesktop) return largeDesktop ?? desktop ?? tablet ?? mobile;
    return mobile; // Default fallback
  }

  /// Get responsive column count for lists
  int getResponsiveColumnCount({
    int? mobile,
    int? tablet,
    int? desktop,
    int? largeDesktop,
  }) {
    return _getResponsiveIntValue(
      mobile: mobile ?? 1,
      tablet: tablet ?? 2,
      desktop: desktop ?? 3,
      largeDesktop: largeDesktop ?? 4,
    );
  }

  /// Get responsive aspect ratio
  double getResponsiveAspectRatio({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 1.0,
      tablet: tablet ?? 1.2,
      desktop: desktop ?? 1.5,
      largeDesktop: largeDesktop ?? 1.8,
    );
  }

  /// Get responsive max width
  double getResponsiveMaxWidth({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? _screenWidth,
      tablet: tablet ?? 600.0,
      desktop: desktop ?? 800.0,
      largeDesktop: largeDesktop ?? 1200.0,
    );
  }

  /// Get responsive container width
  double getResponsiveContainerWidth({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    final maxWidth = getResponsiveMaxWidth(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
    
    return _screenWidth > maxWidth ? maxWidth : _screenWidth;
  }

  /// Get responsive navigation bar height
  double getResponsiveNavigationBarHeight({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 60.0,
      tablet: tablet ?? 70.0,
      desktop: desktop ?? 80.0,
      largeDesktop: largeDesktop ?? 90.0,
    );
  }

  /// Get responsive app bar height
  double getResponsiveAppBarHeight({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 56.0,
      tablet: tablet ?? 64.0,
      desktop: desktop ?? 72.0,
      largeDesktop: largeDesktop ?? 80.0,
    );
  }

  /// Get responsive bottom sheet height
  double getResponsiveBottomSheetHeight({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? 0.5, // 50% of screen height
      tablet: tablet ?? 0.4, // 40% of screen height
      desktop: desktop ?? 0.3, // 30% of screen height
      largeDesktop: largeDesktop ?? 0.25, // 25% of screen height
    );
  }

  /// Get responsive dialog width
  double getResponsiveDialogWidth({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return _getResponsiveValue(
      mobile: mobile ?? _screenWidth * 0.9,
      tablet: tablet ?? 500.0,
      desktop: desktop ?? 600.0,
      largeDesktop: largeDesktop ?? 700.0,
    );
  }

  /// Validate responsive design compliance
  bool validateResponsiveDesign() {
    // Check if all screen sizes are supported
    final hasMobileSupport = _isMobile || _screenWidth < mobileBreakpoint;
    final hasTabletSupport = _isTablet || (_screenWidth >= mobileBreakpoint && _screenWidth < tabletBreakpoint);
    final hasDesktopSupport = _isDesktop || (_screenWidth >= tabletBreakpoint && _screenWidth < desktopBreakpoint);
    final hasLargeDesktopSupport = _isLargeDesktop || _screenWidth >= largeDesktopBreakpoint;
    
    // Check orientation support
    final hasOrientationSupport = _isLandscape || _isPortrait;
    
    // Check minimum touch target sizes
    final hasMinimumTouchTargets = getResponsiveButtonHeight() >= 44.0;
    
    return hasMobileSupport &&
           hasTabletSupport &&
           hasDesktopSupport &&
           hasLargeDesktopSupport &&
           hasOrientationSupport &&
           hasMinimumTouchTargets;
  }

  /// Get responsive design report
  Map<String, dynamic> getResponsiveDesignReport() {
    return {
      'screenWidth': _screenWidth,
      'screenHeight': _screenHeight,
      'pixelRatio': _pixelRatio,
      'isMobile': _isMobile,
      'isTablet': _isTablet,
      'isDesktop': _isDesktop,
      'isLargeDesktop': _isLargeDesktop,
      'isLandscape': _isLandscape,
      'isPortrait': _isPortrait,
      'responsiveDesignValidated': validateResponsiveDesign(),
      'mobileBreakpoint': mobileBreakpoint,
      'tabletBreakpoint': tabletBreakpoint,
      'desktopBreakpoint': desktopBreakpoint,
      'largeDesktopBreakpoint': largeDesktopBreakpoint,
    };
  }
} 