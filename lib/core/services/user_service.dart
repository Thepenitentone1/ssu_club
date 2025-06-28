import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/user.dart';
import '../../shared/models/club.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';

// Privacy settings model
class PrivacySettings {
  final bool profileVisibility;
  final bool showEmail;
  final bool showPhoneNumber;
  final bool showJoinedClubs;
  final bool showEvents;
  final bool allowClubInvitations;
  final bool allowEventInvitations;
  final bool allowMessages;
  final List<String> blockedUsers;

  PrivacySettings({
    this.profileVisibility = true,
    this.showEmail = false,
    this.showPhoneNumber = false,
    this.showJoinedClubs = true,
    this.showEvents = true,
    this.allowClubInvitations = true,
    this.allowEventInvitations = true,
    this.allowMessages = true,
    this.blockedUsers = const [],
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      profileVisibility: map['profileVisibility'] ?? true,
      showEmail: map['showEmail'] ?? false,
      showPhoneNumber: map['showPhoneNumber'] ?? false,
      showJoinedClubs: map['showJoinedClubs'] ?? true,
      showEvents: map['showEvents'] ?? true,
      allowClubInvitations: map['allowClubInvitations'] ?? true,
      allowEventInvitations: map['allowEventInvitations'] ?? true,
      allowMessages: map['allowMessages'] ?? true,
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileVisibility': profileVisibility,
      'showEmail': showEmail,
      'showPhoneNumber': showPhoneNumber,
      'showJoinedClubs': showJoinedClubs,
      'showEvents': showEvents,
      'allowClubInvitations': allowClubInvitations,
      'allowEventInvitations': allowEventInvitations,
      'allowMessages': allowMessages,
      'blockedUsers': blockedUsers,
    };
  }

  PrivacySettings copyWith({
    bool? profileVisibility,
    bool? showEmail,
    bool? showPhoneNumber,
    bool? showJoinedClubs,
    bool? showEvents,
    bool? allowClubInvitations,
    bool? allowEventInvitations,
    bool? allowMessages,
    List<String>? blockedUsers,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showEmail: showEmail ?? this.showEmail,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      showJoinedClubs: showJoinedClubs ?? this.showJoinedClubs,
      showEvents: showEvents ?? this.showEvents,
      allowClubInvitations: allowClubInvitations ?? this.allowClubInvitations,
      allowEventInvitations: allowEventInvitations ?? this.allowEventInvitations,
      allowMessages: allowMessages ?? this.allowMessages,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user model
  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Create new user
  static Future<UserModel> createUser({
    required String email,
    required String firstName,
    required String lastName,
    String? studentId,
    String? course,
    String? yearLevel,
    String? profileImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Automatically assign admin role to edward@gmail.com
      UserRole userRole = UserRole.user;
      if (email.toLowerCase() == 'edward@gmail.com') {
        userRole = UserRole.admin;
      }

      final userModel = UserModel(
        id: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        studentId: studentId,
        course: course,
        yearLevel: yearLevel,
        profileImageUrl: profileImageUrl,
        role: userRole,
        clubMemberships: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());

      return userModel;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? studentId,
    String? course,
    String? yearLevel,
    String? profileImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (studentId != null) updates['studentId'] = studentId;
      if (course != null) updates['course'] = course;
      if (yearLevel != null) updates['yearLevel'] = yearLevel;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update complete user profile (for profile setup)
  static Future<void> updateCompleteUserProfile(UserModel updatedUser) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (user.uid != updatedUser.id) {
        throw Exception('User ID mismatch');
      }

      await _firestore.collection('users').doc(user.uid).update(updatedUser.toFirestore());
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update user role (admin only)
  static Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) {
        throw Exception('Insufficient permissions');
      }

      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Apply to join a club
  static Future<void> applyToJoinClub({
    required String clubId,
    required String clubName,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userModel = await getCurrentUser();
      if (userModel == null) throw Exception('User not found');

      // Check if already a member or has pending application
      final existingMembership = userModel.clubMemberships
          .where((membership) => membership.clubId == clubId)
          .firstOrNull;

      if (existingMembership != null) {
        throw Exception('Already a member or has pending application');
      }

      // Create club membership
      final membership = ClubMembership(
        clubId: clubId,
        clubName: clubName,
        role: UserRole.user,
        status: MembershipStatus.pending,
        joinedAt: DateTime.now(),
        applicationMessage: message,
      );

      // Add to user's club memberships
      final updatedMemberships = [...userModel.clubMemberships, membership];
      
      await _firestore.collection('users').doc(user.uid).update({
        'clubMemberships': updatedMemberships.map((m) => m.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create club application
      await _firestore.collection('club_applications').add({
        'clubId': clubId,
        'userId': user.uid,
        'userName': userModel.fullName,
        'userEmail': userModel.email,
        'userProfileImage': userModel.profileImageUrl,
        'message': message,
        'status': MembershipStatus.pending.toString().split('.').last,
        'appliedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send notifications to club moderators and admins
      try {
        final notificationService = NotificationService();
        
        // Notify club moderators
        await notificationService.sendNotificationToClubModerators(
          clubId: clubId,
          title: 'New Club Application',
          message: '${userModel.fullName} has applied to join $clubName',
          type: NotificationType.clubApplicationPending,
          priority: NotificationPriority.high,
          actionUrl: '/admin/applications',
          data: {
            'clubId': clubId,
            'clubName': clubName,
            'applicantName': userModel.fullName,
            'applicantId': user.uid,
          },
        );

        // Also notify admins (in case they want to be aware of all applications)
        await notificationService.sendNotificationToAdmins(
          title: 'New Club Application',
          message: '${userModel.fullName} has applied to join $clubName',
          type: NotificationType.clubApplicationPending,
          priority: NotificationPriority.normal,
          targetClubId: clubId,
          actionUrl: '/admin/applications',
          data: {
            'clubId': clubId,
            'clubName': clubName,
            'applicantName': userModel.fullName,
            'applicantId': user.uid,
          },
        );
      } catch (e) {
        print('Error sending notifications for club application: $e');
        // Don't throw here - the application was successful, notification failure shouldn't break it
      }
    } catch (e) {
      print('Error applying to join club: $e');
      rethrow;
    }
  }

  // Get user privacy settings
  static Future<PrivacySettings> getUserPrivacySettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return PrivacySettings();

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return PrivacySettings();

      final data = doc.data() as Map<String, dynamic>;
      final settingsData = data['privacySettings'] as Map<String, dynamic>?;
      
      if (settingsData == null) return PrivacySettings();
      
      return PrivacySettings.fromMap(settingsData);
    } catch (e) {
      print('Error getting privacy settings: $e');
      return PrivacySettings();
    }
  }

  // Save user privacy settings
  static Future<void> saveUserPrivacySettings(PrivacySettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).update({
        'privacySettings': settings.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error saving privacy settings: $e');
      rethrow;
    }
  }

  // Block a user
  static Future<void> blockUser(String userIdToBlock) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final currentSettings = await getUserPrivacySettings();
      final updatedBlockedUsers = [...currentSettings.blockedUsers, userIdToBlock];
      
      final updatedSettings = currentSettings.copyWith(
        blockedUsers: updatedBlockedUsers,
      );

      await saveUserPrivacySettings(updatedSettings);
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock a user
  static Future<void> unblockUser(String userIdToUnblock) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final currentSettings = await getUserPrivacySettings();
      final updatedBlockedUsers = currentSettings.blockedUsers
          .where((id) => id != userIdToUnblock)
          .toList();
      
      final updatedSettings = currentSettings.copyWith(
        blockedUsers: updatedBlockedUsers,
      );

      await saveUserPrivacySettings(updatedSettings);
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  // Check if user is blocked
  static Future<bool> isUserBlocked(String userId) async {
    try {
      final currentSettings = await getUserPrivacySettings();
      return currentSettings.blockedUsers.contains(userId);
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Delete user account
  static Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user authentication
      await user.delete();
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }

  // Approve club application (moderator/admin only)
  static Future<void> approveClubApplication({
    required String applicationId,
    required String userId,
    required String clubId,
    UserRole role = UserRole.user,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if current user can moderate this club
      final club = await getClub(clubId);
      if (club == null) throw Exception('Club not found');

      if (!currentUser.canModerate(clubId)) {
        throw Exception('Insufficient permissions');
      }

      // Update application status
      await _firestore.collection('club_applications').doc(applicationId).update({
        'status': MembershipStatus.approved.toString().split('.').last,
        'processedAt': Timestamp.fromDate(DateTime.now()),
        'processedBy': currentUser.id,
      });

      // Update user's club membership
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final memberships = (userData['clubMemberships'] as List<dynamic>)
            .map((m) => ClubMembership.fromMap(m))
            .toList();

        // Update the specific membership
        final membershipIndex = memberships.indexWhere((m) => m.clubId == clubId);
        if (membershipIndex != -1) {
          memberships[membershipIndex] = memberships[membershipIndex].copyWith(
            status: MembershipStatus.member,
            role: role,
            approvedAt: DateTime.now(),
            approvedBy: currentUser.id,
          );

          await _firestore.collection('users').doc(userId).update({
            'clubMemberships': memberships.map((m) => m.toMap()).toList(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      // Add user to club's member list
      await _firestore.collection('clubs').doc(clubId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create chat room for the club if it doesn't exist
      try {
        await ChatService.createClubChatRoom(clubId);
      } catch (e) {
        print('Error creating chat room for club $clubId: $e');
      }
    } catch (e) {
      print('Error approving club application: $e');
      rethrow;
    }
  }

  // Reject club application (moderator/admin only)
  static Future<void> rejectClubApplication({
    required String applicationId,
    required String userId,
    required String clubId,
    String? reason,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if current user can moderate this club
      if (!currentUser.canModerate(clubId)) {
        throw Exception('Insufficient permissions');
      }

      // Update application status
      await _firestore.collection('club_applications').doc(applicationId).update({
        'status': MembershipStatus.rejected.toString().split('.').last,
        'processedAt': Timestamp.fromDate(DateTime.now()),
        'processedBy': currentUser.id,
        'rejectionReason': reason,
      });

      // Update user's club membership
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final memberships = (userData['clubMemberships'] as List<dynamic>)
            .map((m) => ClubMembership.fromMap(m))
            .toList();

        // Remove the membership
        memberships.removeWhere((m) => m.clubId == clubId);

        await _firestore.collection('users').doc(userId).update({
          'clubMemberships': memberships.map((m) => m.toMap()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      print('Error rejecting club application: $e');
      rethrow;
    }
  }

  // Leave club
  static Future<void> leaveClub(String clubId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userModel = await getCurrentUser();
      if (userModel == null) throw Exception('User not found');

      // Remove from user's club memberships
      final updatedMemberships = userModel.clubMemberships
          .where((membership) => membership.clubId != clubId)
          .toList();

      await _firestore.collection('users').doc(user.uid).update({
        'clubMemberships': updatedMemberships.map((m) => m.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Remove from club's member list
      await _firestore.collection('clubs').doc(clubId).update({
        'memberIds': FieldValue.arrayRemove([user.uid]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error leaving club: $e');
      rethrow;
    }
  }

  // Get club details
  static Future<ClubModel?> getClub(String clubId) async {
    try {
      final doc = await _firestore.collection('clubs').doc(clubId).get();
      if (doc.exists) {
        return ClubModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting club: $e');
      return null;
    }
  }

  // Get pending applications for clubs user moderates
  static Future<List<ClubApplication>> getPendingApplications() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return [];

      final moderatedClubIds = currentUser.getModeratedClubIds();
      if (moderatedClubIds.isEmpty) return [];

      final query = await _firestore
          .collection('club_applications')
          .where('clubId', whereIn: moderatedClubIds)
          .where('status', isEqualTo: MembershipStatus.pending.toString().split('.').last)
          .orderBy('appliedAt', descending: true)
          .get();

      return query.docs.map((doc) => ClubApplication.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting pending applications: $e');
      return [];
    }
  }

  // Get all pending applications (admin only)
  static Future<List<ClubApplication>> getAllPendingApplications() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) {
        throw Exception('Insufficient permissions');
      }

      final query = await _firestore
          .collection('club_applications')
          .where('status', isEqualTo: 'pending')
          .orderBy('appliedAt', descending: true)
          .get();
      
      return query.docs.map((doc) => ClubApplication.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all pending applications: $e');
      return [];
    }
  }

  // Get all users (admin only)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) {
        throw Exception('Insufficient permissions');
      }

      final query = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get all users for chat
  static Future<List<UserModel>> getAllUsersForChat() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true) // Optional: only active users
          .get();

      // Optionally, filter out the current user
      return query.docs
          .where((doc) => doc.id != user.uid)
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting users for chat: $e');
      return [];
    }
  }

  // Get club members
  static Future<List<UserModel>> getClubMembers(String clubId) async {
    try {
      final club = await getClub(clubId);
      if (club == null) return [];

      if (club.memberIds.isEmpty) return [];

      final query = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: club.memberIds)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting club members: $e');
      return [];
    }
  }

  // Check if user can perform action
  static Future<bool> canPerformAction({
    required String action,
    String? clubId,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      switch (action) {
        case 'create_event':
          return clubId != null ? currentUser.canCreateEvents(clubId) : false;
        case 'create_announcement':
          return clubId != null ? currentUser.canCreateAnnouncements(clubId) : false;
        case 'approve_applications':
          return clubId != null ? currentUser.canApproveApplications(clubId) : false;
        case 'manage_club_settings':
          return clubId != null ? currentUser.canManageClubSettings(clubId) : false;
        case 'view_all_users':
          return currentUser.isAdmin;
        case 'manage_roles':
          return currentUser.isAdmin;
        default:
          return false;
      }
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  // Stream current user changes
  static Stream<UserModel?> streamCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Stream club members
  static Stream<List<UserModel>> streamClubMembers(String clubId) {
    return _firestore
        .collection('clubs')
        .doc(clubId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return [];
      
      final club = ClubModel.fromFirestore(doc);
      if (club.memberIds.isEmpty) return [];

      final query = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: club.memberIds)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Get all clubs
  static Future<List<ClubModel>> getAllClubs() async {
    try {
      final snapshot = await _firestore.collection('clubs').get();
      return snapshot.docs.map((doc) => ClubModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all clubs: $e');
      return [];
    }
  }

  // Get user's clubs
  static Future<List<ClubModel>> getUserClubs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userModel = await getCurrentUser();
      if (userModel == null) throw Exception('User not found');

      final clubs = await getAllClubs();
      return clubs.where((club) => userModel.clubMemberships.any((m) => m.clubId == club.id)).toList();
    } catch (e) {
      print('Error getting user\'s clubs: $e');
      rethrow;
    }
  }

  // Fetch multiple clubs by their IDs
  static Future<List<ClubModel>> getClubsByIds(List<String> clubIds) async {
    if (clubIds.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('clubs')
          .where(FieldPath.documentId, whereIn: clubIds)
          .get();
      return snapshot.docs.map((doc) => ClubModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching clubs by IDs: $e');
      return [];
    }
  }

  // Get users by a list of IDs
  static Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final query = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();
    return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }
} 