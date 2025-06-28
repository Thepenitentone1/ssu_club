import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/user.dart';
import '../../shared/models/club.dart';

enum NotificationType {
  // Admin notifications
  clubApplicationPending,
  publicEventPending,
  publicAnnouncementPending,
  userRoleChange,
  
  // Moderator notifications
  newClubMember,
  eventRSVP,
  announcementRead,
  clubApplicationApproved,
  clubApplicationRejected,
  
  // User notifications
  clubApplicationStatus,
  eventReminder,
  newAnnouncement,
  clubInvitation,
  eventUpdate,
  announcementUpdate,
  
  // General notifications
  systemUpdate,
  maintenance,
  emergency,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

// Notification settings model
class UserNotificationSettings {
  final bool clubAnnouncements;
  final bool eventReminders;
  final bool newMessages;
  final bool clubInvitations;
  final bool eventUpdates;
  final bool newsAndUpdates;
  final bool emailNotifications;
  final bool pushNotifications;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? notificationSound;
  final bool vibration;

  UserNotificationSettings({
    this.clubAnnouncements = true,
    this.eventReminders = true,
    this.newMessages = true,
    this.clubInvitations = true,
    this.eventUpdates = true,
    this.newsAndUpdates = true,
    this.emailNotifications = false,
    this.pushNotifications = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.notificationSound,
    this.vibration = true,
  });

  factory UserNotificationSettings.fromMap(Map<String, dynamic> map) {
    return UserNotificationSettings(
      clubAnnouncements: map['clubAnnouncements'] ?? true,
      eventReminders: map['eventReminders'] ?? true,
      newMessages: map['newMessages'] ?? true,
      clubInvitations: map['clubInvitations'] ?? true,
      eventUpdates: map['eventUpdates'] ?? true,
      newsAndUpdates: map['newsAndUpdates'] ?? true,
      emailNotifications: map['emailNotifications'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
      quietHoursStart: map['quietHoursStart'],
      quietHoursEnd: map['quietHoursEnd'],
      notificationSound: map['notificationSound'],
      vibration: map['vibration'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clubAnnouncements': clubAnnouncements,
      'eventReminders': eventReminders,
      'newMessages': newMessages,
      'clubInvitations': clubInvitations,
      'eventUpdates': eventUpdates,
      'newsAndUpdates': newsAndUpdates,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'notificationSound': notificationSound,
      'vibration': vibration,
    };
  }

  UserNotificationSettings copyWith({
    bool? clubAnnouncements,
    bool? eventReminders,
    bool? newMessages,
    bool? clubInvitations,
    bool? eventUpdates,
    bool? newsAndUpdates,
    bool? emailNotifications,
    bool? pushNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? notificationSound,
    bool? vibration,
  }) {
    return UserNotificationSettings(
      clubAnnouncements: clubAnnouncements ?? this.clubAnnouncements,
      eventReminders: eventReminders ?? this.eventReminders,
      newMessages: newMessages ?? this.newMessages,
      clubInvitations: clubInvitations ?? this.clubInvitations,
      eventUpdates: eventUpdates ?? this.eventUpdates,
      newsAndUpdates: newsAndUpdates ?? this.newsAndUpdates,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      notificationSound: notificationSound ?? this.notificationSound,
      vibration: vibration ?? this.vibration,
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final String? targetUserId;
  final String? targetClubId;
  final String? targetEventId;
  final String? targetAnnouncementId;
  final String? actionUrl;
  final Map<String, dynamic> data;
  final bool isRead;
  final bool isActioned;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? actionedAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.targetUserId,
    this.targetClubId,
    this.targetEventId,
    this.targetAnnouncementId,
    this.actionUrl,
    this.data = const {},
    this.isRead = false,
    this.isActioned = false,
    required this.createdAt,
    this.readAt,
    this.actionedAt,
  });

  bool get isUrgent => priority == NotificationPriority.urgent;
  bool get isHighPriority => priority == NotificationPriority.high || priority == NotificationPriority.urgent;
  bool get isUnread => !isRead;
  bool get needsAction => !isActioned;

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.systemUpdate,
      ),
      priority: NotificationPriority.values.firstWhere(
        (priority) => priority.toString() == 'NotificationPriority.${data['priority'] ?? 'normal'}',
        orElse: () => NotificationPriority.normal,
      ),
      targetUserId: data['targetUserId'],
      targetClubId: data['targetClubId'],
      targetEventId: data['targetEventId'],
      targetAnnouncementId: data['targetAnnouncementId'],
      actionUrl: data['actionUrl'],
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      isActioned: data['isActioned'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
      actionedAt: data['actionedAt'] != null ? (data['actionedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'targetUserId': targetUserId,
      'targetClubId': targetClubId,
      'targetEventId': targetEventId,
      'targetAnnouncementId': targetAnnouncementId,
      'actionUrl': actionUrl,
      'data': data,
      'isRead': isRead,
      'isActioned': isActioned,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'actionedAt': actionedAt != null ? Timestamp.fromDate(actionedAt!) : null,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    String? targetUserId,
    String? targetClubId,
    String? targetEventId,
    String? targetAnnouncementId,
    String? actionUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isActioned,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? actionedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      targetUserId: targetUserId ?? this.targetUserId,
      targetClubId: targetClubId ?? this.targetClubId,
      targetEventId: targetEventId ?? this.targetEventId,
      targetAnnouncementId: targetAnnouncementId ?? this.targetAnnouncementId,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isActioned: isActioned ?? this.isActioned,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionedAt: actionedAt ?? this.actionedAt,
    );
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'default_channel',
    'Default Notifications',
    description: 'This channel is used for general notifications.',
    importance: Importance.defaultImportance,
  );

  // Collection references
  CollectionReference get _notificationsCollection => 
      _firestore.collection('notifications');
  CollectionReference get _usersCollection => 
      _firestore.collection('users');

  // Get user notification settings
  Future<UserNotificationSettings> getUserNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return UserNotificationSettings();

      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) return UserNotificationSettings();

      final data = doc.data() as Map<String, dynamic>;
      final settingsData = data['notificationSettings'] as Map<String, dynamic>?;
      
      if (settingsData == null) return UserNotificationSettings();
      
      return UserNotificationSettings.fromMap(settingsData);
    } catch (e) {
      print('Error getting notification settings: $e');
      return UserNotificationSettings();
    }
  }

  // Save user notification settings
  Future<void> saveUserNotificationSettings(UserNotificationSettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _usersCollection.doc(user.uid).update({
        'notificationSettings': settings.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update FCM token if push notifications are enabled/disabled
      if (settings.pushNotifications) {
        await _requestPermissions();
      }
    } catch (e) {
      print('Error saving notification settings: $e');
      rethrow;
    }
  }

  // Check if notification should be sent based on settings
  Future<bool> shouldSendNotification(NotificationType type) async {
    try {
      final settings = await getUserNotificationSettings();
      
      if (!settings.pushNotifications) return false;

      // Check quiet hours
      if (settings.quietHoursStart != null && settings.quietHoursEnd != null) {
        final now = DateTime.now();
        final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        if (_isInQuietHours(currentTime, settings.quietHoursStart!, settings.quietHoursEnd!)) {
          return false;
        }
      }

      // Check specific notification types
      switch (type) {
        case NotificationType.newAnnouncement:
          return settings.clubAnnouncements;
        case NotificationType.eventReminder:
          return settings.eventReminders;
        case NotificationType.clubInvitation:
          return settings.clubInvitations;
        case NotificationType.eventUpdate:
        case NotificationType.announcementUpdate:
          return settings.eventUpdates;
        case NotificationType.systemUpdate:
          return settings.newsAndUpdates;
        default:
          return true;
      }
    } catch (e) {
      print('Error checking notification settings: $e');
      return true; // Default to sending if there's an error
    }
  }

  // Check if current time is in quiet hours
  bool _isInQuietHours(String currentTime, String startTime, String endTime) {
    try {
      final current = _parseTime(currentTime);
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);

      if (start <= end) {
        // Same day quiet hours (e.g., 22:00 to 08:00)
        return current >= start && current <= end;
      } else {
        // Overnight quiet hours (e.g., 22:00 to 08:00)
        return current >= start || current <= end;
      }
    } catch (e) {
      print('Error parsing quiet hours: $e');
      return false;
    }
  }

  // Parse time string (HH:MM) to minutes since midnight
  int _parseTime(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  static Future<void> initialize() async {
    try {
      print('Initializing notification service...');
      await _requestPermissions();
      await _initializeLocalNotifications();
      await _initializeFirebaseMessaging();
      _setupMessageHandlers();
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('FCM Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_defaultChannel);
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  static Future<void> _initializeFirebaseMessaging() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveTokenToDatabase(token);
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        _saveTokenToDatabase(newToken);
      });
    } catch (e) {
      print('Error initializing Firebase messaging: $e');
    }
  }

  static void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.notification?.title}');
      _handleNotificationTap(message);
    });
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM token saved to database');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              color: const Color(0xFF3B82F6),
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'announcement') {
      print('Navigate to announcement: ${data['announcementId']}');
    } else if (data['type'] == 'event') {
      print('Navigate to event: ${data['eventId']}');
    } else if (data['type'] == 'chat') {
      print('Navigate to chat');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? targetClubId,
    String? targetEventId,
    String? targetAnnouncementId,
    String? actionUrl,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        title: title,
        message: message,
        type: type,
        priority: priority,
        targetUserId: userId,
        targetClubId: targetClubId,
        targetEventId: targetEventId,
        targetAnnouncementId: targetAnnouncementId,
        actionUrl: actionUrl,
        data: data,
        createdAt: DateTime.now(),
      );

      await _notificationsCollection.add(notification.toFirestore());
    } catch (e) {
      print('Error sending notification to user: $e');
      rethrow;
    }
  }

  Future<void> sendNotificationToAdmins({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? targetClubId,
    String? targetEventId,
    String? targetAnnouncementId,
    String? actionUrl,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final adminUsers = await _usersCollection
          .where('role', isEqualTo: 'admin')
          .get();

      for (final doc in adminUsers.docs) {
        await sendNotificationToUser(
          userId: doc.id,
          title: title,
          message: message,
          type: type,
          priority: priority,
          targetClubId: targetClubId,
          targetEventId: targetEventId,
          targetAnnouncementId: targetAnnouncementId,
          actionUrl: actionUrl,
          data: data,
        );
      }
    } catch (e) {
      print('Error sending notification to admins: $e');
      rethrow;
    }
  }

  Future<void> sendNotificationToClubModerators({
    required String clubId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? targetEventId,
    String? targetAnnouncementId,
    String? actionUrl,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final clubDoc = await _firestore.collection('clubs').doc(clubId).get();
      if (!clubDoc.exists) return;

      final club = ClubModel.fromFirestore(clubDoc);
      final moderatorIds = [...club.moderatorIds, ...club.adminIds];

      for (final moderatorId in moderatorIds) {
        await sendNotificationToUser(
          userId: moderatorId,
          title: title,
          message: message,
          type: type,
          priority: priority,
          targetClubId: clubId,
          targetEventId: targetEventId,
          targetAnnouncementId: targetAnnouncementId,
          actionUrl: actionUrl,
          data: data,
        );
      }
    } catch (e) {
      print('Error sending notification to club moderators: $e');
      rethrow;
    }
  }

  Future<void> sendNotificationToDepartment({
    required Department department,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? targetClubId,
    String? targetEventId,
    String? targetAnnouncementId,
    String? actionUrl,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final departmentUsers = await _usersCollection
          .where('department', isEqualTo: department.toString().split('.').last)
          .get();

      for (final doc in departmentUsers.docs) {
        await sendNotificationToUser(
          userId: doc.id,
          title: title,
          message: message,
          type: type,
          priority: priority,
          targetClubId: targetClubId,
          targetEventId: targetEventId,
          targetAnnouncementId: targetAnnouncementId,
          actionUrl: actionUrl,
          data: data,
        );
      }
    } catch (e) {
      print('Error sending notification to department: $e');
      rethrow;
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationsCollection
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Stream<int> getUnreadNotificationsCount(String userId) {
    return _notificationsCollection
        .where('targetUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markNotificationAsActioned(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isActioned': true,
        'actionedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error marking notification as actioned: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> clearAllNotifications(String userId) async {
    try {
      final notifications = await _notificationsCollection
          .where('targetUserId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
      rethrow;
    }
  }

  Future<void> notifyClubApplicationPending({
    required String clubId,
    required String clubName,
    required String applicantName,
  }) async {
    await sendNotificationToAdmins(
      title: 'New Club Application Pending',
      message: '$applicantName has applied to join $clubName',
      type: NotificationType.clubApplicationPending,
      priority: NotificationPriority.high,
      targetClubId: clubId,
      actionUrl: '/admin/applications',
      data: {
        'clubId': clubId,
        'clubName': clubName,
        'applicantName': applicantName,
      },
    );
  }

  Future<void> notifyPublicEventPending({
    required String eventId,
    required String eventTitle,
    required String clubName,
  }) async {
    await sendNotificationToAdmins(
      title: 'Public Event Pending Approval',
      message: '$clubName has created a public event: $eventTitle',
      type: NotificationType.publicEventPending,
      priority: NotificationPriority.high,
      targetEventId: eventId,
      actionUrl: '/admin/events',
      data: {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'clubName': clubName,
      },
    );
  }

  Future<void> notifyPublicAnnouncementPending({
    required String announcementId,
    required String announcementTitle,
    required String clubName,
  }) async {
    await sendNotificationToAdmins(
      title: 'Public Announcement Pending Approval',
      message: '$clubName has created a public announcement: $announcementTitle',
      type: NotificationType.publicAnnouncementPending,
      priority: NotificationPriority.high,
      targetAnnouncementId: announcementId,
      actionUrl: '/admin/announcements',
      data: {
        'announcementId': announcementId,
        'announcementTitle': announcementTitle,
        'clubName': clubName,
      },
    );
  }

  Future<void> notifyNewClubMember({
    required String clubId,
    required String clubName,
    required String newMemberName,
  }) async {
    await sendNotificationToClubModerators(
      clubId: clubId,
      title: 'New Club Member',
      message: '$newMemberName has joined $clubName',
      type: NotificationType.newClubMember,
      priority: NotificationPriority.normal,
      data: {
        'clubId': clubId,
        'clubName': clubName,
        'newMemberName': newMemberName,
      },
    );
  }

  Future<void> notifyEventRSVP({
    required String clubId,
    required String eventId,
    required String eventTitle,
    required String attendeeName,
  }) async {
    await sendNotificationToClubModerators(
      clubId: clubId,
      title: 'New Event RSVP',
      message: '$attendeeName has RSVP\'d to $eventTitle',
      type: NotificationType.eventRSVP,
      priority: NotificationPriority.normal,
      targetEventId: eventId,
      data: {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'attendeeName': attendeeName,
      },
    );
  }

  Future<void> notifyClubApplicationStatus({
    required String userId,
    required String clubName,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: isApproved ? 'Club Application Approved' : 'Club Application Rejected',
      message: isApproved 
          ? 'Your application to join $clubName has been approved!'
          : 'Your application to join $clubName has been rejected. ${rejectionReason ?? ''}',
      type: NotificationType.clubApplicationStatus,
      priority: isApproved ? NotificationPriority.normal : NotificationPriority.high,
      data: {
        'clubName': clubName,
        'isApproved': isApproved,
        'rejectionReason': rejectionReason,
      },
    );
  }

  Future<void> notifyEventReminder({
    required String userId,
    required String eventTitle,
    required DateTime eventDate,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Event Reminder',
      message: 'Don\'t forget! $eventTitle is tomorrow at ${eventDate.toString()}',
      type: NotificationType.eventReminder,
      priority: NotificationPriority.high,
      data: {
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
      },
    );
  }

  Future<void> notifyNewAnnouncement({
    required String userId,
    required String announcementTitle,
    required String clubName,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'New Announcement',
      message: '$clubName has posted a new announcement: $announcementTitle',
      type: NotificationType.newAnnouncement,
      priority: NotificationPriority.normal,
      data: {
        'announcementTitle': announcementTitle,
        'clubName': clubName,
      },
    );
  }

  Future<void> notifySystemUpdate({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final allUsers = await _usersCollection.get();
      
      for (final doc in allUsers.docs) {
        await sendNotificationToUser(
          userId: doc.id,
          title: title,
          message: message,
          type: NotificationType.systemUpdate,
          priority: priority,
        );
      }
    } catch (e) {
      print('Error sending system notification: $e');
      rethrow;
    }
  }

  Future<void> notifyEmergency({
    required String title,
    required String message,
    Department? department,
  }) async {
    if (department != null) {
      await sendNotificationToDepartment(
        department: department,
        title: title,
        message: message,
        type: NotificationType.emergency,
        priority: NotificationPriority.urgent,
      );
    } else {
      await notifySystemUpdate(
        title: title,
        message: message,
        priority: NotificationPriority.urgent,
      );
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
}
