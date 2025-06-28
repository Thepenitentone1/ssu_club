# Role-Based System Implementation

## Overview

The SSU Club Hub app implements a comprehensive three-tier role-based system with department-based filtering and notification management. This system ensures proper access control, content moderation, and user management across different departments and campuses.

## User Roles

### 1. Admin Role
**Highest level of access and control**

**Permissions:**
- View and manage all club applications across all departments
- Approve/reject public events and announcements
- Manage user roles (promote/demote users)
- View all departments and campuses
- Access comprehensive analytics
- Suspend/activate users
- Override any content restrictions
- Send system-wide notifications

**Key Features:**
- Admin Panel with 4 main tabs:
  - Applications: Review pending club applications
  - Public Content: Approve/reject public events and announcements
  - Users: Manage user roles and accounts
  - Analytics: View system statistics

**Notifications:**
- Receives notifications for all pending applications
- Receives notifications for public content requiring approval
- Can send system-wide notifications

### 2. Moderator Role
**Department and club-specific management**

**Permissions:**
- Manage club members within their moderated clubs
- Create and manage events for their clubs
- Create and manage announcements for their clubs
- Approve/reject applications to their clubs
- Moderate chat rooms for their clubs
- View department-specific content
- Manage club settings

**Key Features:**
- Moderator Panel for club management
- Department-based content filtering
- Club member management
- Event and announcement creation
- Application approval system

**Notifications:**
- Receives notifications for new club applications
- Receives notifications for event RSVPs
- Receives notifications for club-related activities

### 3. User Role
**Basic access with information viewing**

**Permissions:**
- View approved content from their department
- Join clubs (with approval)
- RSVP to events
- View announcements
- Participate in club chats
- Update profile information
- Save events and announcements

**Key Features:**
- Department-based content filtering
- Club membership management
- Event participation
- Profile customization

**Notifications:**
- Receives notifications for application status
- Receives event reminders
- Receives new announcement notifications
- Receives club invitations

## Department-Based System

### Departments Supported
Based on SSU's structure (https://ssu.edu.ph/):

1. **College of Arts and Sciences (CAS)**
2. **College of Business and Entrepreneurship (CBE)**
3. **College of Education (COE)**
4. **College of Engineering (COENG)**
5. **College of Technology (COT)**
6. **College of Agriculture (COA)**
7. **College of Fisheries (COF)**
8. **College of Forestry and Environmental Science (COFES)**
9. **College of Medicine (COM)**
10. **College of Nursing (CON)**
11. **College of Pharmacy (COPH)**
12. **College of Law (COL)**
13. **Graduate School (GS)**
14. **Senior High School (SHS)**

### Campuses Supported
1. **Main Campus (Sogod)**
2. **Salcedo Campus**
3. **San Juan Campus**
4. **Hinunangan Campus**
5. **Hinundayan Campus**
6. **Saint Bernard Campus**
7. **San Miguel Campus**
8. **Liloan Campus**
9. **San Francisco Campus**
10. **San Ricardo Campus**
11. **Anahawan Campus**
12. **Silago Campus**
13. **Santa Rita Campus**
14. **Macrohon Campus**
15. **Malitbog Campus**
16. **Tomas Oppus Campus**
17. **Limasawa Campus**
18. **Padre Burgos Campus**

## Content Visibility System

### Club Visibility Levels
1. **Public**: Visible to all users (requires admin approval)
2. **Department**: Visible only to users in the same department
3. **Private**: Visible only to club members and moderators

### Event Visibility Levels
1. **Public**: Visible to all users (requires admin approval)
2. **Department**: Visible only to users in the same department
3. **Club**: Visible only to club members
4. **Private**: Visible only to club members and moderators

### Announcement Visibility Levels
1. **Public**: Visible to all users (requires admin approval)
2. **Department**: Visible only to users in the same department
3. **Club**: Visible only to club members
4. **Private**: Visible only to club members and moderators

## Notification System

### Notification Types
1. **Admin Notifications:**
   - Club application pending
   - Public event pending approval
   - Public announcement pending approval
   - User role changes

2. **Moderator Notifications:**
   - New club member
   - Event RSVP
   - Announcement read
   - Club application approved/rejected

3. **User Notifications:**
   - Club application status
   - Event reminders
   - New announcements
   - Club invitations
   - Event updates

4. **System Notifications:**
   - System updates
   - Maintenance alerts
   - Emergency notifications

### Notification Priorities
1. **Low**: General information
2. **Normal**: Standard notifications
3. **High**: Important updates
4. **Urgent**: Critical alerts

## Database Structure

### User Model Enhancements
```dart
class UserModel {
  // Basic fields
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  
  // Role and permissions
  final UserRole role;
  final List<ClubMembership> clubMemberships;
  
  // Department and campus
  final Department? department;
  final Campus? campus;
  
  // Preferences and saved content
  final List<String> notificationPreferences;
  final List<String> savedEvents;
  final List<String> savedAnnouncements;
}
```

### Club Model Enhancements
```dart
class ClubModel {
  // Basic fields
  final String id;
  final String name;
  final String description;
  
  // Visibility and approval
  final ClubVisibility visibility;
  final ClubStatus status;
  final bool isPublicContentApproved;
  
  // Department and campus
  final Department department;
  final Campus campus;
  
  // Members and moderators
  final List<String> memberIds;
  final List<String> moderatorIds;
  final List<String> adminIds;
}
```

### Event Model Enhancements
```dart
class EventModel {
  // Basic fields
  final String id;
  final String title;
  final String description;
  
  // Visibility and approval
  final EventVisibility visibility;
  final EventStatus status;
  final bool needsApproval;
  
  // Department and campus
  final Department? department;
  final Campus? campus;
  
  // Attendees and RSVPs
  final List<String> attendeeIds;
  final List<String> rsvpIds;
}
```

### Announcement Model Enhancements
```dart
class AnnouncementModel {
  // Basic fields
  final String id;
  final String title;
  final String content;
  
  // Visibility and approval
  final AnnouncementVisibility visibility;
  final AnnouncementStatus status;
  final bool needsApproval;
  
  // Department and campus
  final Department? department;
  final Campus? campus;
  
  // Read tracking
  final List<String> readByIds;
  final List<String> importantForIds;
}
```

## Security Rules

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User access control
    match /users/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || isAdmin());
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Club access control
    match /clubs/{clubId} {
      allow read: if request.auth != null && (
        resource.data.visibility == 'public' ||
        isMember(clubId) ||
        isModerator(clubId) ||
        isAdmin() ||
        (resource.data.visibility == 'department' && sameDepartment(resource.data.department))
      );
      allow write: if request.auth != null && (
        isModerator(clubId) ||
        isAdmin()
      );
    }
    
    // Event access control
    match /events/{eventId} {
      allow read: if request.auth != null && (
        resource.data.visibility == 'public' ||
        isMember(resource.data.clubId) ||
        isModerator(resource.data.clubId) ||
        isAdmin() ||
        (resource.data.visibility == 'department' && sameDepartment(resource.data.department))
      );
      allow write: if request.auth != null && (
        isModerator(resource.data.clubId) ||
        isAdmin()
      );
    }
    
    // Announcement access control
    match /announcements/{announcementId} {
      allow read: if request.auth != null && (
        resource.data.visibility == 'public' ||
        isMember(resource.data.clubId) ||
        isModerator(resource.data.clubId) ||
        isAdmin() ||
        (resource.data.visibility == 'department' && sameDepartment(resource.data.department))
      );
      allow write: if request.auth != null && (
        isModerator(resource.data.clubId) ||
        isAdmin()
      );
    }
  }
}
```

## UI Behavior

### Role-Based UI Elements
1. **Admin Panel**: Only visible to admin users
2. **Moderator Panel**: Only visible to moderators and admins
3. **Department Filter**: Shows only relevant departments based on user role
4. **Content Creation**: Only available to moderators and admins
5. **Approval Actions**: Only available to appropriate roles

### Navigation Structure
```
Main App
├── Home (All users)
├── Clubs (Department-filtered)
├── Events (Department-filtered)
├── Announcements (Department-filtered)
├── Chat (Club-based)
├── Profile (All users)
├── Admin Panel (Admin only)
├── Moderator Panel (Moderators + Admin)
└── Notifications (All users)
```

## Implementation Files

### Core Models
- `lib/shared/models/user.dart` - Enhanced UserModel with role system
- `lib/shared/models/club.dart` - Enhanced ClubModel with visibility
- `lib/shared/models/event.dart` - Enhanced EventModel with approval
- `lib/shared/models/announcement.dart` - Enhanced AnnouncementModel

### Services
- `lib/core/services/user_service.dart` - User management and role operations
- `lib/core/services/notification_service.dart` - Notification system
- `lib/core/services/chat_service.dart` - Role-based chat functionality

### UI Components
- `lib/features/admin/presentation/pages/admin_panel_page.dart` - Admin panel
- `lib/features/admin/presentation/pages/moderator_panel_page.dart` - Moderator panel
- `lib/features/auth/presentation/pages/notifications_page.dart` - Notifications
- `lib/shared/widgets/notification_badge.dart` - Notification badge widget

## Usage Examples

### Creating a Public Event (Moderator)
```dart
// Moderator creates event
final event = EventModel(
  title: 'Department Seminar',
  visibility: EventVisibility.public, // Requires admin approval
  // ... other fields
);

// Admin receives notification
await notificationService.notifyPublicEventPending(
  eventId: event.id,
  eventTitle: event.title,
  clubName: club.name,
);
```

### Approving Club Application (Admin)
```dart
// Admin approves application
await userService.approveClubApplication(
  userId: userId,
  clubId: clubId,
  approvedBy: 'admin',
);

// User receives notification
await notificationService.notifyClubApplicationStatus(
  userId: userId,
  clubName: clubName,
  isApproved: true,
);
```

### Department-Based Content Filtering
```dart
// User sees only their department's content
final userDepartment = currentUser.department;
final filteredClubs = clubs.where((club) => 
  club.visibility == ClubVisibility.public ||
  club.department == userDepartment ||
  user.isMemberOf(club.id)
).toList();
```

## Future Enhancements

1. **Advanced Analytics**: Detailed reporting for admins
2. **Bulk Operations**: Mass approval/rejection capabilities
3. **Audit Trail**: Complete history of all actions
4. **Role Templates**: Predefined role configurations
5. **Department Hierarchies**: Sub-department management
6. **Advanced Notifications**: Custom notification rules
7. **Content Scheduling**: Future content publication
8. **Export Features**: Data export for reporting

## Testing

### Role Testing Scenarios
1. **Admin Access**: Verify admin can access all features
2. **Moderator Limits**: Verify moderators can only manage their clubs
3. **User Restrictions**: Verify users cannot access admin features
4. **Department Filtering**: Verify content is properly filtered
5. **Notification Flow**: Verify notifications are sent to correct roles

### Security Testing
1. **Permission Bypass**: Attempt to access restricted content
2. **Role Escalation**: Attempt to change roles without permission
3. **Content Approval**: Verify approval workflow
4. **Data Isolation**: Verify department data isolation

## Deployment Considerations

1. **Database Migration**: Update existing user records with roles
2. **Security Rules**: Deploy updated Firestore security rules
3. **User Communication**: Inform users about new role system
4. **Training**: Provide training for admins and moderators
5. **Monitoring**: Set up monitoring for role-based activities

This role-based system provides a robust foundation for managing the SSU Club Hub app with proper access control, content moderation, and user management across all departments and campuses. 