# SSU Club Hub - Role-Based System Setup Guide

## 🚀 Quick Setup Instructions

### 1. Deploy Firestore Rules
First, deploy the updated Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

### 2. Create Admin User
The system automatically creates an admin user when someone signs up with `edward@gmail.com`. 

**Admin Credentials:**
- Email: `edward@gmail.com`
- Password: `Admin123!` (you can change this in the setup script)

### 3. Test the System

#### For Admin (edward@gmail.com):
1. **Sign in** with `edward@gmail.com`
2. **Go to Profile** - you should see:
   - Admin Panel option
   - Moderator Panel option
   - Role badge showing "Admin"
3. **Create Events/Announcements** - you'll see floating action buttons
4. **Access Admin Panel** - manage applications and content

#### For Regular Users:
1. **Sign up** with any other email (e.g., `student@gmail.com`)
2. **Apply to clubs** - your application will be sent to admins
3. **Create content** - will require admin approval
4. **View notifications** - get updates on your applications

## 🎯 New Features Available

### Admin Features:
- **Admin Panel**: Manage club applications, approve/reject content
- **User Management**: View all users, change roles
- **Analytics**: System statistics and user data
- **Department Filtering**: Filter content by department

### Moderator Features:
- **Moderator Panel**: Manage club-specific content
- **Club Applications**: Approve/reject applications for their clubs
- **Content Creation**: Create events and announcements (requires admin approval)

### User Features:
- **Club Applications**: Apply to join clubs
- **Notifications**: Get updates on application status
- **Content Viewing**: View approved events and announcements

## 🔧 How to Test

### 1. Test Admin Role:
```bash
# Sign in as admin
Email: edward@gmail.com
Password: Admin123!
```

### 2. Test User Role:
```bash
# Sign up as regular user
Email: student@gmail.com
Password: Student123!
```

### 3. Test Club Application Flow:
1. Regular user applies to a club
2. Admin receives notification
3. Admin approves/rejects in Admin Panel
4. User receives notification of status

### 4. Test Content Creation:
1. User creates event/announcement
2. Admin receives notification for approval
3. Admin approves/rejects in Admin Panel
4. Content becomes visible to all users

## 📱 Navigation

### Admin Navigation:
- **Profile** → **Admin Panel** (red button)
- **Profile** → **Moderator Panel** (orange button)
- **Events** → **Floating Action Button** (create events)
- **Announcements** → **Floating Action Button** (create announcements)

### User Navigation:
- **Profile** → **Notifications** (view application status)
- **Clubs** → **Apply to clubs**
- **Events/Announcements** → **View only** (no create buttons)

## 🔍 Troubleshooting

### If features don't appear:
1. **Check user role**: Make sure you're signed in with the correct account
2. **Clear app cache**: Restart the app
3. **Check Firestore rules**: Make sure they're deployed correctly
4. **Check user document**: Verify the user document exists in Firestore

### If notifications don't work:
1. **Check notification permissions**: Allow notifications in app settings
2. **Check Firestore**: Verify notifications collection exists
3. **Check user role**: Make sure you have the correct permissions

## 📊 Firestore Collections

The system uses these collections:
- `users` - User profiles and roles
- `clubs` - Club information
- `events` - Event data
- `announcements` - Announcement data
- `club_applications` - Club membership applications
- `notifications` - User notifications

## 🎉 Success Indicators

You'll know the system is working when:
- ✅ Admin sees red "Admin Panel" button in profile
- ✅ Regular users see "Apply" buttons on clubs
- ✅ Notifications appear for pending applications
- ✅ Floating action buttons appear for admins/moderators
- ✅ Content requires approval before being visible

## 🔐 Security

- Only admins can change user roles
- Only admins can approve public content
- Users can only see their own notifications
- Club moderators can only manage their own clubs
- All operations require proper authentication 