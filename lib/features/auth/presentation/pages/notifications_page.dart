import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/models/announcement.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _filterType = 'all'; // all, unread, urgent

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1E3A8A), // Primary blue color
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Notifications'),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: Text('Unread Only'),
              ),
              const PopupMenuItem(
                value: 'urgent',
                child: Text('Urgent Only'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllNotifications,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterType == 'all',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = 'all';
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Unread'),
                  selected: _filterType == 'unread',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = 'unread';
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Urgent'),
                  selected: _filterType == 'urgent',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = 'urgent';
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.getUserNotifications(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data ?? [];
                final filteredNotifications = _filterNotifications(notifications);

                if (filteredNotifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = filteredNotifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    switch (_filterType) {
      case 'unread':
        return notifications.where((n) => n.isUnread).toList();
      case 'urgent':
        return notifications.where((n) => n.isUrgent).toList();
      default:
        return notifications;
    }
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isUnread ? 4 : 1,
      color: notification.isUnread ? Colors.blue[50] : null,
      child: ListTile(
        leading: _buildNotificationIcon(notification),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.normal,
            color: notification.isUrgent ? Colors.red : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: notification.isUnread
            ? IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => _markAsRead(notification),
                tooltip: 'Mark as read',
              )
            : null,
        onTap: () => _handleNotificationTap(notification),
        onLongPress: () => _showNotificationOptions(notification),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.clubApplicationPending:
      case NotificationType.publicEventPending:
      case NotificationType.publicAnnouncementPending:
        iconData = Icons.pending;
        iconColor = Colors.orange;
        break;
      case NotificationType.clubApplicationStatus:
        iconData = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case NotificationType.eventReminder:
        iconData = Icons.event;
        iconColor = Colors.green;
        break;
      case NotificationType.newAnnouncement:
        iconData = Icons.announcement;
        iconColor = Colors.purple;
        break;
      case NotificationType.emergency:
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      case NotificationType.systemUpdate:
        iconData = Icons.system_update;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await _notificationService.markNotificationAsRead(notification.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notification as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsActioned(NotificationModel notification) async {
    try {
      await _notificationService.markNotificationAsActioned(notification.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as actioned'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notification as actioned: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if unread
    if (notification.isUnread) {
      _markAsRead(notification);
    }

    // Handle navigation based on notification type
    if (notification.actionUrl != null) {
      // Navigate to the action URL
      // This would typically involve navigation to a specific page
      _navigateToAction(notification);
    } else {
      // Show notification details
      _showNotificationDetails(notification);
    }
  }

  void _navigateToAction(NotificationModel notification) {
    // Handle navigation based on notification type and data
    switch (notification.type) {
      case NotificationType.clubApplicationPending:
        // Navigate to admin panel applications tab
        Navigator.pushNamed(context, '/admin/applications');
        break;
      case NotificationType.publicEventPending:
        // Navigate to admin panel events tab
        Navigator.pushNamed(context, '/admin/events');
        break;
      case NotificationType.publicAnnouncementPending:
        // Navigate to admin panel announcements tab
        Navigator.pushNamed(context, '/admin/announcements');
        break;
      case NotificationType.clubApplicationStatus:
        // Navigate to user's club memberships
        Navigator.pushNamed(context, '/profile/clubs');
        break;
      case NotificationType.eventReminder:
      case NotificationType.eventUpdate:
        // Navigate to events page and show specific event details
        if (notification.targetEventId != null) {
          _navigateToEventsPageAndShowEvent(notification.targetEventId!);
        }
        break;
      case NotificationType.newAnnouncement:
      case NotificationType.announcementUpdate:
        // Navigate to announcements page and show specific announcement details
        if (notification.targetAnnouncementId != null) {
          _navigateToAnnouncementsPageAndShowAnnouncement(notification.targetAnnouncementId!);
        }
        break;
      default:
        // Show notification details
        _showNotificationDetails(notification);
    }
  }

  void _navigateToEventsPageAndShowEvent(String eventId) async {
    try {
      // Fetch the event details from Firestore
      final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        final event = EventModel.fromFirestore(eventDoc);
        _showEventDetailsDialog(event);
      } else {
        // If event not found, navigate to events page
        Navigator.pushNamed(context, '/main');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event not found. Please check the Events tab.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // If error, navigate to events page
      Navigator.pushNamed(context, '/main');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading event. Please check the Events tab.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToAnnouncementsPageAndShowAnnouncement(String announcementId) async {
    try {
      // Fetch the announcement details from Firestore
      final announcementDoc = await FirebaseFirestore.instance.collection('announcements').doc(announcementId).get();
      if (announcementDoc.exists) {
        final announcement = AnnouncementModel.fromFirestore(announcementDoc);
        _showAnnouncementDetailsDialog(announcement);
      } else {
        // If announcement not found, navigate to announcements page
        Navigator.pushNamed(context, '/main');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement not found. Please check the Announcements tab.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // If error, navigate to announcements page
      Navigator.pushNamed(context, '/main');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading announcement. Please check the Announcements tab.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showEventDetailsDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.imageUrl != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(event.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(event.startDate)),
              _buildDetailRow('Time', '${DateFormat('HH:mm').format(event.startDate)} - ${DateFormat('HH:mm').format(event.endDate)}'),
              if (event.location != null) _buildDetailRow('Location', event.location!),
              _buildDetailRow('Organizer', event.clubName),
              _buildDetailRow('Attendees', '${event.attendeeCount}/${event.maxAttendees}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/main');
            },
            child: const Text('View All Events'),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDetailsDialog(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (announcement.imageUrl != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(announcement.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                announcement.content,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Author', announcement.clubName),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(announcement.createdAt)),
              _buildDetailRow('Type', announcement.typeName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/main');
            },
            child: const Text('View All Announcements'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Type: ${notification.type.toString().split('.').last}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Priority: ${notification.priority.toString().split('.').last}'),
            Text('Created: ${_formatDate(notification.createdAt)}'),
            if (notification.readAt != null)
              Text('Read: ${_formatDate(notification.readAt!)}'),
            if (notification.actionedAt != null)
              Text('Actioned: ${_formatDate(notification.actionedAt!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!notification.isActioned)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsActioned(notification);
              },
              child: const Text('Mark as Actioned'),
            ),
        ],
      ),
    );
  }

  void _showNotificationOptions(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationDetails(notification);
              },
            ),
            if (notification.isUnread)
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Mark as Read'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsRead(notification);
                },
              ),
            if (!notification.isActioned)
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Mark as Actioned'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsActioned(notification);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteNotification(notification);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.clearAllNotifications(currentUser.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 