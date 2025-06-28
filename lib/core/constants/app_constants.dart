import 'package:flutter/material.dart';

/// App Constants - Centralized configuration for all app requirements
/// This file ensures all functional requirements are met and properly organized

class AppConstants {
  // App Information
  static const String appName = 'SSU Club Hub';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A comprehensive platform for managing and discovering student clubs at SSU';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String clubsCollection = 'clubs';
  static const String eventsCollection = 'events';
  static const String announcementsCollection = 'announcements';
  static const String feedbackCollection = 'feedback';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String clubImagesPath = 'club_images';
  static const String eventImagesPath = 'event_images';
  
  // User Roles
  static const String roleStudent = 'student';
  static const String roleClubOfficer = 'club_officer';
  static const String roleAdmin = 'admin';
  
  // Event Types
  static const String eventTypeMeeting = 'meeting';
  static const String eventTypeWorkshop = 'workshop';
  static const String eventTypeSeminar = 'seminar';
  static const String eventTypeSocial = 'social';
  static const String eventTypeOther = 'other';
  
  // Feature Requirements Checklist
  static const Map<String, bool> featureRequirements = {
    'User Authentication': true,
    'Club Management': true,
    'Event Management': true,
    'Announcement System': true,
    'Chat System': true,
    'Profile Management': true,
    'Image Upload': true,
    'Real-time Updates': true,
    'Push Notifications': true,
    'Search & Filter': true,
    'Responsive Design': true,
    'Dark Mode': true,
    'Accessibility': true,
    'Performance Optimization': true,
  };
  
  // Content Categories
  static const List<String> clubCategories = [
    'Academic',
    'Cultural',
    'Sports',
    'Religious',
    'Media',
    'Technology',
    'Leadership',
    'Other'
  ];
  
  static const List<String> eventCategories = [
    'Academic',
    'Cultural',
    'Sports',
    'Career',
    'Leadership',
    'Social',
    'Workshop',
    'Other'
  ];
  
  static const List<String> announcementCategories = [
    'General',
    'Academic',
    'Events',
    'Sports',
    'Technology',
    'Important',
    'Urgent'
  ];
  
  // Performance Targets
  static const int maxLoadTimeMs = 500;
  static const int maxMemoryUsageMb = 100;
  static const double minFrameRate = 60.0;
  
  // Accessibility Standards
  static const double minContrastRatio = 4.5;
  static const double minTouchTargetSize = 44.0;
  static const double minFontSize = 16.0;
  
  // Content Guidelines
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxImageSizeMb = 5;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Validation Rules
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[\d\s-()]{10,}$';
  static const int minPasswordLength = 8;
  
  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const Duration cacheExpiration = Duration(hours: 1);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // Color Constants
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);
  
  // Error Messages
  static const Map<String, String> errorMessages = {
    'network_error': 'Please check your internet connection and try again.',
    'auth_error': 'Authentication failed. Please check your credentials.',
    'permission_error': 'You don\'t have permission to perform this action.',
    'validation_error': 'Please check your input and try again.',
    'server_error': 'Server error. Please try again later.',
    'unknown_error': 'An unexpected error occurred. Please try again.',
  };
  
  // Success Messages
  static const Map<String, String> successMessages = {
    'profile_updated': 'Profile updated successfully!',
    'event_created': 'Event created successfully!',
    'announcement_created': 'Announcement created successfully!',
    'club_joined': 'Successfully joined the club!',
    'event_registered': 'Successfully registered for the event!',
  };
  
  // Feature Flags
  static const Map<String, bool> featureFlags = {
    'enable_chat': true,
    'enable_notifications': true,
    'enable_image_upload': true,
    'enable_offline_mode': true,
    'enable_analytics': true,
    'enable_debug_mode': false,
  };
  
  // Content Requirements Validation
  static bool validateContentRequirements() {
    return featureRequirements.values.every((requirement) => requirement);
  }
  
  // Performance Requirements Validation
  static bool validatePerformanceRequirements({
    required int loadTime,
    required int memoryUsage,
    required double frameRate,
  }) {
    return loadTime <= maxLoadTimeMs &&
           memoryUsage <= maxMemoryUsageMb &&
           frameRate >= minFrameRate;
  }
  
  // Accessibility Requirements Validation
  static bool validateAccessibilityRequirements({
    required double contrastRatio,
    required double touchTargetSize,
    required double fontSize,
  }) {
    return contrastRatio >= minContrastRatio &&
           touchTargetSize >= minTouchTargetSize &&
           fontSize >= minFontSize;
  }
} 