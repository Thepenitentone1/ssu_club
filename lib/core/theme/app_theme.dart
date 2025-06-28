import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// Comprehensive App Theme System
/// Provides highly intuitive, visually appealing, and accessible design
class AppTheme {
  static final AppTheme _instance = AppTheme._internal();
  factory AppTheme() => _instance;
  AppTheme._internal();

  // Color Palette - WCAG 2.1 AA Compliant
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _secondaryBlue = Color(0xFF3B82F6);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _warningAmber = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _successGreen = Color(0xFF22C55E);
  static const Color _neutralGray = Color(0xFF6B7280);
  static const Color _lightGray = Color(0xFFF3F4F6);
  static const Color _darkGray = Color(0xFF374151);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  // Typography Scale - Accessible Font Sizes
  static const double _fontSizeXs = 12.0;
  static const double _fontSizeSm = 14.0;
  static const double _fontSizeBase = 16.0;
  static const double _fontSizeLg = 18.0;
  static const double _fontSizeXl = 20.0;
  static const double _fontSize2xl = 24.0;
  static const double _fontSize3xl = 30.0;
  static const double _fontSize4xl = 36.0;

  // Spacing Scale
  static const double _spacingXs = 4.0;
  static const double _spacingSm = 8.0;
  static const double _spacingMd = 16.0;
  static const double _spacingLg = 24.0;
  static const double _spacingXl = 32.0;
  static const double _spacing2xl = 48.0;

  // Border Radius Scale
  static const double _radiusSm = 4.0;
  static const double _radiusMd = 8.0;
  static const double _radiusLg = 12.0;
  static const double _radiusXl = 16.0;
  static const double _radiusFull = 9999.0;

  // Elevation Scale
  static const double _elevationSm = 2.0;
  static const double _elevationMd = 4.0;
  static const double _elevationLg = 8.0;
  static const double _elevationXl = 16.0;

  /// Light Theme - Primary theme for the app
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: _primaryBlue,
        secondary: _secondaryBlue,
        tertiary: _accentGreen,
        surface: _white,
        error: _errorRed,
        onPrimary: _white,
        onSecondary: _white,
        onTertiary: _white,
        onSurface: _black,
        onError: _white,
        outline: _neutralGray,
        outlineVariant: _lightGray,
        shadow: _black,
        scrim: _black,
        inverseSurface: _darkGray,
        inversePrimary: _secondaryBlue,
        surfaceTint: _primaryBlue,
        surfaceContainerHighest: _lightGray,
        onSurfaceVariant: _darkGray,
      ),

      // Typography
      textTheme: _buildTextTheme(),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryBlue,
        foregroundColor: _white,
        elevation: _elevationMd,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeLg,
          fontWeight: FontWeight.w600,
          color: _white,
        ),
        iconTheme: const IconThemeData(color: _white, size: 24),
        actionsIconTheme: const IconThemeData(color: _white, size: 24),
        toolbarHeight: 64,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(_radiusLg)),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: _white,
        elevation: _elevationSm,
        shadowColor: _black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        margin: const EdgeInsets.all(_spacingSm),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: _white,
          elevation: _elevationSm,
          shadowColor: _black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _spacingLg,
            vertical: _spacingMd,
          ),
          minimumSize: const Size(44, 44), // Accessibility touch target
          textStyle: GoogleFonts.poppins(
            fontSize: _fontSizeBase,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlue,
          side: const BorderSide(color: _primaryBlue, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _spacingLg,
            vertical: _spacingMd,
          ),
          minimumSize: const Size(44, 44), // Accessibility touch target
          textStyle: GoogleFonts.poppins(
            fontSize: _fontSizeBase,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _spacingMd,
            vertical: _spacingSm,
          ),
          minimumSize: const Size(44, 44), // Accessibility touch target
          textStyle: GoogleFonts.poppins(
            fontSize: _fontSizeBase,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _spacingMd,
          vertical: _spacingMd,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: _fontSizeBase,
          color: _neutralGray,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: _fontSizeBase,
          color: _neutralGray.withOpacity(0.7),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: _fontSizeSm,
          color: _errorRed,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryBlue,
        foregroundColor: _white,
        elevation: _elevationLg,
        shape: CircleBorder(),
        iconSize: 24,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _white,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: _neutralGray,
        type: BottomNavigationBarType.fixed,
        elevation: _elevationMd,
        selectedLabelStyle: TextStyle(fontSize: _fontSizeSm, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: _fontSizeSm),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _lightGray,
        selectedColor: _primaryBlue,
        disabledColor: _lightGray,
        labelStyle: GoogleFonts.poppins(fontSize: _fontSizeSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _spacingMd),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _lightGray,
        thickness: 1,
        space: _spacingMd,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: _neutralGray,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: _primaryBlue,
        size: 24,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkGray,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeBase,
          color: _white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: _elevationLg,
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: _white,
        elevation: _elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeXl,
          fontWeight: FontWeight.w600,
          color: _black,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeBase,
          color: _darkGray,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _white,
        elevation: _elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusLg)),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarTheme(
        labelColor: _primaryBlue,
        unselectedLabelColor: _neutralGray,
        indicatorColor: _primaryBlue,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontSize: _fontSizeBase, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: _fontSizeBase),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _white;
          return _neutralGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryBlue;
          return _lightGray;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryBlue;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryBlue;
          return _neutralGray;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: _primaryBlue,
        inactiveTrackColor: _lightGray,
        thumbColor: _primaryBlue,
        overlayColor: _primaryBlue.withOpacity(0.2),
        valueIndicatorColor: _primaryBlue,
        valueIndicatorTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeSm,
          color: _white,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryBlue,
        linearTrackColor: _lightGray,
        circularTrackColor: _lightGray,
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _darkGray,
          borderRadius: BorderRadius.circular(_radiusMd),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: _fontSizeSm,
          color: _white,
        ),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 3),
      ),

      // Page Transitions Theme
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Dark Theme - Alternative theme for accessibility
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: _secondaryBlue,
        secondary: _accentGreen,
        tertiary: _warningAmber,
        surface: _darkGray,
        error: _errorRed,
        onPrimary: _white,
        onSecondary: _black,
        onTertiary: _black,
        onSurface: _white,
        onError: _white,
        outline: _neutralGray,
        outlineVariant: _darkGray,
        shadow: _black,
        scrim: _black,
        inverseSurface: _white,
        inversePrimary: _primaryBlue,
        surfaceTint: _secondaryBlue,
        surfaceContainerHighest: _darkGray,
        onSurfaceVariant: _lightGray,
      ),

      // Typography
      textTheme: _buildTextTheme(isDark: true),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _darkGray,
        foregroundColor: _white,
        elevation: _elevationMd,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeLg,
          fontWeight: FontWeight.w600,
          color: _white,
        ),
        iconTheme: const IconThemeData(color: _white, size: 24),
        actionsIconTheme: const IconThemeData(color: _white, size: 24),
        toolbarHeight: 64,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(_radiusLg)),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: _darkGray,
        elevation: _elevationSm,
        shadowColor: _black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        margin: const EdgeInsets.all(_spacingSm),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _secondaryBlue,
          foregroundColor: _white,
          elevation: _elevationSm,
          shadowColor: _black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _spacingLg,
            vertical: _spacingMd,
          ),
          minimumSize: const Size(44, 44), // Accessibility touch target
          textStyle: GoogleFonts.poppins(
            fontSize: _fontSizeBase,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _secondaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: const BorderSide(color: _errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _spacingMd,
          vertical: _spacingMd,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: _fontSizeBase,
          color: _lightGray,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: _fontSizeBase,
          color: _lightGray.withOpacity(0.7),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: _fontSizeSm,
          color: _errorRed,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkGray,
        selectedItemColor: _secondaryBlue,
        unselectedItemColor: _lightGray,
        type: BottomNavigationBarType.fixed,
        elevation: _elevationMd,
        selectedLabelStyle: TextStyle(fontSize: _fontSizeSm, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: _fontSizeSm),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _black,
        selectedColor: _secondaryBlue,
        disabledColor: _black,
        labelStyle: GoogleFonts.poppins(fontSize: _fontSizeSm, color: _white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _spacingMd),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _darkGray,
        thickness: 1,
        space: _spacingMd,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: _lightGray,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: _secondaryBlue,
        size: 24,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _black,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeBase,
          color: _white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: _elevationLg,
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: _darkGray,
        elevation: _elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeXl,
          fontWeight: FontWeight.w600,
          color: _white,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeBase,
          color: _lightGray,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkGray,
        elevation: _elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusLg)),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarTheme(
        labelColor: _secondaryBlue,
        unselectedLabelColor: _lightGray,
        indicatorColor: _secondaryBlue,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontSize: _fontSizeBase, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: _fontSizeBase),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _white;
          return _lightGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _secondaryBlue;
          return _black;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _secondaryBlue;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _secondaryBlue;
          return _lightGray;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: _secondaryBlue,
        inactiveTrackColor: _black,
        thumbColor: _secondaryBlue,
        overlayColor: _secondaryBlue.withOpacity(0.2),
        valueIndicatorColor: _secondaryBlue,
        valueIndicatorTextStyle: GoogleFonts.poppins(
          fontSize: _fontSizeSm,
          color: _white,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _secondaryBlue,
        linearTrackColor: _black,
        circularTrackColor: _black,
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _black,
          borderRadius: BorderRadius.circular(_radiusMd),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: _fontSizeSm,
          color: _white,
        ),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 3),
      ),

      // Page Transitions Theme
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Build comprehensive text theme with accessibility considerations
  TextTheme _buildTextTheme({bool isDark = false}) {
    final baseColor = isDark ? _white : _black;
    final secondaryColor = isDark ? _lightGray : _darkGray;

    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: _fontSize4xl,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: _fontSize3xl,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
        letterSpacing: -0.25,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: _fontSize2xl,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: _fontSize2xl,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: _fontSizeXl,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: _fontSizeLg,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: _fontSizeLg,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: _fontSizeBase,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: _fontSizeSm,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: _fontSizeBase,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: _fontSizeBase,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: _fontSizeSm,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: _fontSizeBase,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: _fontSizeSm,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: _fontSizeXs,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        height: 1.4,
      ),
    );
  }

  /// Get theme data based on brightness
  ThemeData getThemeData(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  /// Get color scheme based on brightness
  ColorScheme getColorScheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme.colorScheme : lightTheme.colorScheme;
  }

  /// Get text theme based on brightness
  TextTheme getTextTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme.textTheme : lightTheme.textTheme;
  }

  /// Get spacing value
  static double getSpacing(String size) {
    switch (size) {
      case 'xs': return _spacingXs;
      case 'sm': return _spacingSm;
      case 'md': return _spacingMd;
      case 'lg': return _spacingLg;
      case 'xl': return _spacingXl;
      case '2xl': return _spacing2xl;
      default: return _spacingMd;
    }
  }

  /// Get radius value
  static double getRadius(String size) {
    switch (size) {
      case 'sm': return _radiusSm;
      case 'md': return _radiusMd;
      case 'lg': return _radiusLg;
      case 'xl': return _radiusXl;
      case 'full': return _radiusFull;
      default: return _radiusMd;
    }
  }

  /// Get elevation value
  static double getElevation(String size) {
    switch (size) {
      case 'sm': return _elevationSm;
      case 'md': return _elevationMd;
      case 'lg': return _elevationLg;
      case 'xl': return _elevationXl;
      default: return _elevationMd;
    }
  }

  /// Get font size value
  static double getFontSize(String size) {
    switch (size) {
      case 'xs': return _fontSizeXs;
      case 'sm': return _fontSizeSm;
      case 'base': return _fontSizeBase;
      case 'lg': return _fontSizeLg;
      case 'xl': return _fontSizeXl;
      case '2xl': return _fontSize2xl;
      case '3xl': return _fontSize3xl;
      case '4xl': return _fontSize4xl;
      default: return _fontSizeBase;
    }
  }
} 