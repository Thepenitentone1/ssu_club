# Role-Based Features Documentation

## Overview

The SSU Club Hub app now implements a comprehensive role-based system with three distinct user roles: **User**, **Moderator**, and **Admin**. Each role has specific permissions and capabilities within the app.

## User Roles

### 1. User (Regular Member)
**Default role for all registered users**

**Permissions:**
- View public clubs, events, and announcements
- Join clubs (requires approval)
- RSVP to events
- Send messages in club chat rooms
- View club members
- Update personal profile

**Restrictions:**
- Cannot create events or announcements
- Cannot approve/reject club applications
- Cannot moderate content
- Cannot manage club settings

### 2. Moderator
**Club-specific role with elevated permissions**

**Permissions:**
- All User permissions
- Create and manage events for their clubs
- Create and manage announcements for their clubs
- Approve/reject club membership applications
- Manage club members
- Moderate club chat rooms
- Set content privacy (public/private/members-only)
- Manage RSVPs for club events
- Access moderator panel

**Restrictions:**
- Can only moderate clubs they are assigned to
- Cannot manage other clubs
- Cannot change user roles globally

### 3. Admin
**System-wide role with full permissions**

**Permissions:**
- All Moderator permissions
- Manage all clubs and users
- Change user roles
- Access admin panel
- View system-wide analytics
- Manage global settings
- Override any permission restrictions

## Core Features

### 1. User Management System

#### User Model (`lib/shared/models/user.dart`)
```dart
enum UserRole {
  user,
  moderator,
  admin,
}

enum MembershipStatus {
  pending,
  approved,
  rejected,
  member,
}

class UserModel {
  // User properties
  final UserRole role;
  final List<ClubMembership> clubMemberships;
  
  // Permission methods
  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator || role == UserRole.admin;
  bool canModerate(String clubId) => isAdmin || isModeratorOf(clubId);
  bool canCreateEvents(String clubId) => isAdmin || isModeratorOf(clubId);
  bool canCreateAnnouncements(String clubId) => isAdmin || isModeratorOf(clubId);
}
```

#### Club Membership System
```dart
class ClubMembership {
  final String clubId;
  final String clubName;
  final UserRole role;
  final MembershipStatus status;
  final DateTime joinedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? applicationMessage;
}
```

### 2. Club Management

#### Enhanced Club Model (`lib/shared/models/club.dart`)
```dart
enum ClubPrivacy {
  public,
  private,
  membersOnly,
}

class Club {
  final List<String> moderatorIds;
  final List<String> memberIds;
  final ClubPrivacy privacy;
  final bool requiresApproval;
  
  // Permission methods
  bool isContentVisibleToUser(String userId, List<String> userClubIds, bool isUserMember);
  bool canUserJoin(String userId);
  bool isUserMember(String userId);
  bool isUserModerator(String userId);
}
```

#### Club Application System
```dart
class ClubApplication {
  final String clubId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? message;
  final MembershipStatus status;
  final DateTime appliedAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? rejectionReason;
}
```

### 3. Event Management

#### Enhanced Event Model (`lib/shared/models/event.dart`)
```dart
enum EventPrivacy {
  public,
  private,
  membersOnly,
}

enum RSVPStatus {
  going,
  maybe,
  notGoing,
  pending,
}

class Event {
  final EventPrivacy privacy;
  final String createdBy;
  final bool isApproved;
  final List<EventRSVP> rsvps;
  
  // Permission methods
  bool isVisibleToUser(String userId, List<String> userClubIds, bool isUserMember);
  bool canUserRSVP(String userId);
  bool canUserModerate(String userId);
}
```

### 4. Announcement Management

#### Enhanced Announcement Model (`lib/shared/models/announcement.dart`)
```dart
enum AnnouncementPrivacy {
  public,
  private,
  membersOnly,
}

enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent,
}

class Announcement {
  final AnnouncementPrivacy privacy;
  final AnnouncementPriority priority;
  final String createdBy;
  final bool isApproved;
  final List<String> viewedBy;
  final List<String> confirmedBy;
  
  // Permission methods
  bool isVisibleToUser(String userId, List<String> userClubIds, bool isUserMember);
  bool canUserModerate(String userId);
  bool canUserEdit(String userId);
  bool canUserDelete(String userId);
}
```

### 5. Chat System

#### Enhanced Chat Service (`lib/core/services/chat_service.dart`)
```dart
enum ChatType {
  club,
  direct,
  group,
}

class ChatRoom {
  final ChatType type;
  final String? clubId;
  final List<String> memberIds;
  final List<String> moderatorIds;
}

class ChatMessage {
  final String senderId;
  final bool isEdited;
  final List<String> readBy;
  final List<String> reactions;
}
```

**Chat Features:**
- Club-specific chat rooms
- Role-based message permissions
- Message editing and deletion (moderators only)
- File and image sharing
- Message reactions
- Read receipts

### 6. User Service

#### Comprehensive User Management (`lib/core/services/user_service.dart`)
```dart
class UserService {
  // User management
  static Future<UserModel?> getCurrentUser();
  static Future<UserModel> createUser({...});
  static Future<void> updateUserProfile({...});
  static Future<void> updateUserRole(String userId, UserRole newRole);
  
  // Club membership
  static Future<void> applyToJoinClub({...});
  static Future<void> approveClubApplication({...});
  static Future<void> rejectClubApplication({...});
  static Future<void> leaveClub(String clubId);
  
  // Permissions
  static Future<bool> canPerformAction({required String action, String? clubId});
  
  // Data access
  static Future<List<ClubApplication>> getPendingApplications();
  static Future<List<UserModel>> getClubMembers(String clubId);
  static Future<List<UserModel>> getAllUsers(); // Admin only
}
```

### 7. Moderator Panel

#### Comprehensive Management Interface (`lib/features/admin/presentation/pages/moderator_panel_page.dart`)

**Features:**
- **Applications Tab**: Review and approve/reject club membership applications
- **My Clubs Tab**: Manage clubs where user is a moderator
- **Events Tab**: Manage club events (coming soon)
- **Announcements Tab**: Manage club announcements (coming soon)

**Application Management:**
- View pending applications with user details
- Approve applications with role assignment
- Reject applications with reason
- View application history

**Club Management:**
- View club members and moderators
- Manage club settings
- Monitor club activity
- Access club-specific features

## Privacy and Security

### Content Visibility Rules

1. **Public Content**: Visible to all users
2. **Private Content**: Visible only to club members
3. **Members-Only Content**: Visible only to approved club members

### Permission Checks

All content access is validated through permission methods:
```dart
// Example: Event visibility
bool isVisibleToUser(String userId, List<String> userClubIds, bool isUserMember) {
  switch (privacy) {
    case EventPrivacy.public:
      return true;
    case EventPrivacy.private:
      return userClubIds.contains(clubId);
    case EventPrivacy.membersOnly:
      return isUserMember;
  }
}
```

## User Interface Features

### 1. Role-Based Navigation
- Different menu items based on user role
- Moderator panel access for moderators
- Admin panel access for admins

### 2. Permission-Based UI Elements
- Create buttons only visible to moderators/admins
- Edit/delete options based on permissions
- Privacy settings for content creators

### 3. Enhanced Chat Interface
- Club-specific chat rooms
- Role-based message controls
- Moderator tools for chat management

### 4. Application Management
- Streamlined application review process
- Bulk approval/rejection capabilities
- Application history tracking

## Database Structure

### Collections

1. **users**
   - User profiles with roles and memberships
   - Club membership history
   - Permission settings

2. **clubs**
   - Club information with privacy settings
   - Member and moderator lists
   - Club-specific settings

3. **club_applications**
   - Pending membership applications
   - Application status and history
   - Approval/rejection tracking

4. **events**
   - Event details with privacy settings
   - RSVP management
   - Creator and approval information

5. **announcements**
   - Announcement content with privacy
   - Priority and status tracking
   - View and confirmation tracking

6. **chat_rooms**
   - Club-specific chat rooms
   - Member and moderator lists
   - Chat room settings

7. **messages**
   - Chat messages with metadata
   - Read receipts and reactions
   - Message editing history

## Security Rules

### Firestore Security Rules
```javascript
// Example: Club access rules
match /clubs/{clubId} {
  allow read: if resource.data.privacy == 'public' || 
              request.auth.uid in resource.data.memberIds ||
              request.auth.uid in resource.data.moderatorIds;
  allow write: if request.auth.uid in resource.data.moderatorIds ||
               get(/databases/$(database.name)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

## Future Enhancements

### Planned Features

1. **Advanced Analytics**
   - Club activity metrics
   - User engagement tracking
   - Content performance analytics

2. **Notification System**
   - Role-based notifications
   - Application status updates
   - Event reminders

3. **Content Moderation**
   - Automated content filtering
   - Report management system
   - Content approval workflows

4. **Advanced Permissions**
   - Granular permission system
   - Custom role creation
   - Permission inheritance

5. **Integration Features**
   - Calendar integration
   - Email notifications
   - Social media sharing

## Implementation Notes

### Best Practices

1. **Always check permissions** before allowing actions
2. **Use role-based UI** to show/hide features
3. **Validate on both client and server** side
4. **Log all administrative actions** for audit trails
5. **Provide clear feedback** for permission denials

### Performance Considerations

1. **Cache user permissions** to reduce database queries
2. **Use efficient queries** for club membership checks
3. **Implement pagination** for large lists
4. **Optimize real-time updates** for chat and notifications

### Testing Strategy

1. **Unit tests** for permission logic
2. **Integration tests** for role-based workflows
3. **UI tests** for role-specific features
4. **Security tests** for permission validation

## Conclusion

The role-based system provides a comprehensive foundation for managing user permissions and content access in the SSU Club Hub app. The modular design allows for easy extension and modification of permissions as requirements evolve.

The system ensures that:
- Users can only access content they're authorized to see
- Moderators have appropriate tools to manage their clubs
- Admins have full system control
- All actions are properly validated and logged
- The user experience is intuitive and role-appropriate 