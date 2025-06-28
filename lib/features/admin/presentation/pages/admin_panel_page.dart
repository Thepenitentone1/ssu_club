import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/models/club.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/models/announcement.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../features/events/data/services/event_service.dart';
import '../../../../features/announcements/data/services/announcement_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../features/admin/presentation/pages/moderator_panel_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../../core/services/chat_service.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final EventService _eventService = EventService();
  final AnnouncementService _announcementService = AnnouncementService();
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _announcementsSubscription;
  
  Department? _selectedDepartment;
  String _searchQuery = '';
  int _selectedIndex = 0;
  List<UserModel> _allUsers = [];
  List<UserModel> _searchFilteredUsers = [];
  List<ClubApplication> _pendingApplications = [];
  List<EventModel> _pendingEvents = [];
  List<AnnouncementModel> _pendingAnnouncements = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  // Analytics state variables
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _adminCount = 0;
  int _moderatorCount = 0;
  int _totalClubs = 0;
  int _activeClubs = 0;
  int _pendingApplicationsCount = 0;
  int _totalEvents = 0;
  int _pendingEventsCount = 0;
  int _totalAnnouncements = 0;
  int _pendingAnnouncementsCount = 0;

  int _publicContentTabIndex = 0; // 0 = Events, 1 = Announcements

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllUsers();
    _loadPendingApplications();
    _listenForPendingContent();
    _searchController.addListener(_filterUsers);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    _eventsSubscription?.cancel();
    _announcementsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Applications', icon: Icon(Icons.person_add)),
            Tab(text: 'Public Content', icon: Icon(Icons.public)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Deletion Requests', icon: Icon(Icons.delete_forever)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Department filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: LayoutBuilder(builder: (context, constraints) {
              bool useRow = constraints.maxWidth > 600;
              if (useRow) {
                return Row(
                  children: [
                    Expanded(child: _buildDepartmentFilter()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSearchField()),
                  ],
                );
              } else {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDepartmentFilter(),
                    const SizedBox(height: 16),
                    _buildSearchField(),
                  ],
                );
              }
            }),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationsTab(),
                _buildPublicContentTab(),
                _buildUsersTab(),
                _buildAnalyticsTab(),
                _buildDeletionRequestsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listenForPendingContent,
        tooltip: 'Refresh Pending Content',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildApplicationsTab() {
    if (_isLoading) return const Center(child: LoadingWidget());
    if (_pendingApplications.isEmpty) {
      return const Center(child: Text('No pending applications.'));
    }

    return RefreshIndicator(
      onRefresh: _loadPendingApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingApplications.length,
        itemBuilder: (context, index) {
          final application = _pendingApplications[index];
          return _buildApplicationItem(application);
        },
      ),
    );
  }

  Widget _buildApplicationItem(ClubApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: application.userProfileImage != null
                      ? NetworkImage(application.userProfileImage!)
                      : null,
                  child: application.userProfileImage == null
                      ? Text(application.userName.substring(0, 1))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(application.userEmail, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            FutureBuilder<ClubModel?>(
              future: UserService.getClub(application.clubId),
              builder: (context, snapshot) {
                final clubName = snapshot.data?.name ?? 'Loading...';
                return Text.rich(
                  TextSpan(
                    text: 'Wants to join: ',
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: clubName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                );
              }
            ),
            if (application.message != null && application.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Message: "${application.message}"'),
            ],
            const SizedBox(height: 8),
            Text('Applied: ${_formatDate(application.appliedAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _approveApplication(application),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _rejectApplication(application),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicContentTab() {
    if (_isLoading) return const Center(child: LoadingWidget());
    if (_pendingEvents.isEmpty && _pendingAnnouncements.isEmpty) {
      return const Center(child: Text('No pending public events or announcements.'));
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() { _publicContentTabIndex = 0; });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _publicContentTabIndex == 0 ? Colors.blue : Colors.grey[300],
                foregroundColor: _publicContentTabIndex == 0 ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Pending Events (${_pendingEvents.length})'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                setState(() { _publicContentTabIndex = 1; });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _publicContentTabIndex == 1 ? Colors.blue : Colors.grey[300],
                foregroundColor: _publicContentTabIndex == 1 ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Pending Announcements (${_pendingAnnouncements.length})'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _publicContentTabIndex == 0
            ? _buildPendingEventsList()
            : _buildPendingAnnouncementsList(),
        ),
      ],
    );
  }

  Widget _buildPendingEventsList() {
    if (_pendingEvents.isEmpty) {
      return const Center(child: Text('No pending events.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._pendingEvents.map((event) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(event.title),
            subtitle: Text('By: ${event.clubName}\n${event.description}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View',
                  onPressed: () => _viewEventDetails(event),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'Accept',
                  onPressed: () => _approveEvent(event.id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Reject',
                  onPressed: () => _rejectEvent(event.id),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPendingAnnouncementsList() {
    if (_pendingAnnouncements.isEmpty) {
      return const Center(child: Text('No pending announcements.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._pendingAnnouncements.map((announcement) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(announcement.title),
            subtitle: Text('By: ${announcement.clubName}\n${announcement.content}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View',
                  onPressed: () => _viewAnnouncementDetails(announcement),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'Accept',
                  onPressed: () => _approveAnnouncement(announcement.id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Reject',
                  onPressed: () => _rejectAnnouncement(announcement.id),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList() ?? [];

        // Filter by department if selected
        final filteredUsers = _selectedDepartment != null
            ? users.where((user) => user.department == _selectedDepartment).toList()
            : users;

        // Filter by search query
        final searchFilteredUsers = _searchQuery.isNotEmpty
            ? filteredUsers.where((user) =>
                user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                user.studentId?.toLowerCase().contains(_searchQuery.toLowerCase()) == true
              ).toList()
            : filteredUsers;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: searchFilteredUsers.length,
          itemBuilder: (context, index) {
            final user = searchFilteredUsers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(user.initials)
                      : null,
                ),
                title: Text(user.fullName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Role: ${user.role.toString().split('.').last}'),
                    Text('Department: ${user.departmentName}'),
                    Text('Campus: ${user.campusName}'),
                    Text('Email: ${user.email}'),
                    if (user.studentId != null) Text('Student ID: ${user.studentId}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleUserAction(value, user),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'chat',
                      child: Text('Chat'),
                    ),
                    const PopupMenuItem(
                      value: 'change_role',
                      child: Text('Change Role'),
                    ),
                    const PopupMenuItem(
                      value: 'view_details',
                      child: Text('View Details'),
                    ),
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Text('Suspend User'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Statistics
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final users = snapshot.data!.docs;
                  final totalUsers = users.length;
                  final activeUsers = users.where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false).length;
                  final adminCount = users.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'admin').length;
                  final moderatorCount = users.where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'moderator').length;

                  return _buildAnalyticsCard(
                    title: 'User Statistics',
                    children: [
                      _buildStatItem('Total Users', totalUsers.toString()),
                      _buildStatItem('Active Users', activeUsers.toString()),
                      _buildStatItem('Admins', adminCount.toString()),
                      _buildStatItem('Moderators', moderatorCount.toString()),
                    ],
                  );
                }
                return _buildAnalyticsCard(
                  title: 'User Statistics',
                  children: [
                    _buildStatItem('Total Users', 'Loading...'),
                    _buildStatItem('Active Users', 'Loading...'),
                    _buildStatItem('Admins', 'Loading...'),
                    _buildStatItem('Moderators', 'Loading...'),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Club Statistics
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final clubs = snapshot.data!.docs;
                  final totalClubs = clubs.length;
                  final activeClubs = clubs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'active').length;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('club_applications').where('status', isEqualTo: 'pending').snapshots(),
                    builder: (context, applicationsSnapshot) {
                      final pendingApplications = applicationsSnapshot.data?.docs.length ?? 0;

                      return _buildAnalyticsCard(
                        title: 'Club Statistics',
                        children: [
                          _buildStatItem('Total Clubs', totalClubs.toString()),
                          _buildStatItem('Active Clubs', activeClubs.toString()),
                          _buildStatItem('Pending Applications', pendingApplications.toString()),
                        ],
                      );
                    },
                  );
                }
                return _buildAnalyticsCard(
                  title: 'Club Statistics',
                  children: [
                    _buildStatItem('Total Clubs', 'Loading...'),
                    _buildStatItem('Active Clubs', 'Loading...'),
                    _buildStatItem('Pending Applications', 'Loading...'),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Content Statistics
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('events').snapshots(),
              builder: (context, eventsSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
                  builder: (context, announcementsSnapshot) {
                    final totalEvents = eventsSnapshot.data?.docs.length ?? 0;
                    final pendingEvents = eventsSnapshot.data?.docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'pending').length ?? 0;
                    final totalAnnouncements = announcementsSnapshot.data?.docs.length ?? 0;
                    final pendingAnnouncements = announcementsSnapshot.data?.docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'pending').length ?? 0;

                    return _buildAnalyticsCard(
                      title: 'Content Statistics',
                      children: [
                        _buildStatItem('Total Events', totalEvents.toString()),
                        _buildStatItem('Pending Events', pendingEvents.toString()),
                        _buildStatItem('Total Announcements', totalAnnouncements.toString()),
                        _buildStatItem('Pending Announcements', pendingAnnouncements.toString()),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Recent Activity
            _buildAnalyticsCard(
              title: 'Recent Activity',
              children: [
                _buildStatItem('Last Updated', DateTime.now().toString().substring(0, 19)),
                _buildStatItem('System Status', 'Online'),
                _buildStatItem('Database', 'Connected'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentFilter() {
    return DropdownButtonFormField<Department>(
      value: _selectedDepartment,
      decoration: const InputDecoration(
        labelText: 'Filter by Department',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        const DropdownMenuItem<Department>(
          value: null,
          child: Text('All Departments'),
        ),
        ...Department.values.map((dept) => DropdownMenuItem(
              value: dept,
              child: Text(_getDepartmentName(dept)),
            )),
      ],
      onChanged: (Department? value) {
        setState(() {
          _selectedDepartment = value;
        });
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search Users',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (value) => _filterUsers(),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _approveApplication(ClubApplication application) async {
    try {
      // We need the club object for the notification, unfortunately.
      final club = await UserService.getClub(application.clubId);
      if (club == null) throw Exception("Club not found");

      await UserService.approveClubApplication(
        applicationId: application.id,
        userId: application.userId,
        clubId: application.clubId,
      );

      await _notificationService.notifyClubApplicationStatus(
        userId: application.userId,
        clubName: club.name,
        isApproved: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application approved for ${application.userName}'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh the list
      _loadPendingApplications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectApplication(ClubApplication application) async {
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        // We need the club object for the notification, unfortunately.
        final club = await UserService.getClub(application.clubId);
        if (club == null) throw Exception("Club not found");

        await UserService.rejectClubApplication(
          applicationId: application.id,
          userId: application.userId,
          clubId: application.clubId,
          reason: reason,
        );

        await _notificationService.notifyClubApplicationStatus(
          userId: application.userId,
          clubName: club.name,
          isApproved: false,
          rejectionReason: reason,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application for ${application.userName} rejected'),
            backgroundColor: Colors.orange,
          ),
        );
         // Refresh the list
        _loadPendingApplications();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveEvent(String eventId) async {
    final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return;
    final event = EventModel.fromFirestore(eventDoc);
    await FirebaseFirestore.instance.collection('events').doc(eventId).update({'status': 'approved'});
    _listenForPendingContent();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event approved!')));
    // Notify moderators
    await NotificationService().sendNotificationToClubModerators(
      clubId: event.clubId,
      title: 'Event Approved',
      message: 'The event "${event.title}" has been approved by admin.',
      type: NotificationType.eventUpdate,
      targetEventId: eventId,
      data: {'eventId': eventId, 'clubName': event.clubName},
    );
    // Notify all users about new event
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    for (final doc in usersSnap.docs) {
      await NotificationService().sendNotificationToUser(
        userId: doc.id,
        title: 'New Event',
        message: '${event.clubName} has a new event: ${event.title}',
        type: NotificationType.eventUpdate,
        targetEventId: eventId,
        data: {'eventId': eventId, 'clubName': event.clubName},
      );
    }
  }

  Future<void> _rejectEvent(String eventId) async {
    String? reason;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Event'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
          onChanged: (value) => reason = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('events').doc(eventId).update({'status': 'rejected', 'rejectionReason': reason});
              Navigator.pop(context);
              _listenForPendingContent();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event rejected.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAnnouncement(String announcementId) async {
    final announcementDoc = await FirebaseFirestore.instance.collection('announcements').doc(announcementId).get();
    if (!announcementDoc.exists) return;
    final announcement = AnnouncementModel.fromFirestore(announcementDoc);
    
    await FirebaseFirestore.instance.collection('announcements').doc(announcementId).update({'status': 'approved'});
    _listenForPendingContent();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement approved!')));
    
    // Notify moderators
    await NotificationService().sendNotificationToClubModerators(
      clubId: announcement.clubId,
      title: 'Announcement Approved',
      message: 'The announcement "${announcement.title}" has been approved by admin.',
      type: NotificationType.announcementUpdate,
      targetAnnouncementId: announcementId,
      data: {'announcementId': announcementId, 'clubName': announcement.clubName},
    );
    
    // Notify all users about new announcement
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    for (final doc in usersSnap.docs) {
      await NotificationService().sendNotificationToUser(
        userId: doc.id,
        title: 'New Announcement',
        message: '${announcement.clubName} has a new announcement: ${announcement.title}',
        type: NotificationType.newAnnouncement,
        targetAnnouncementId: announcementId,
        data: {'announcementId': announcementId, 'clubName': announcement.clubName},
      );
    }
  }

  Future<void> _rejectAnnouncement(String announcementId) async {
    String? reason;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Announcement'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
          onChanged: (value) => reason = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('announcements').doc(announcementId).update({'status': 'rejected', 'rejectionReason': reason});
              Navigator.pop(context);
              _listenForPendingContent();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement rejected.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'chat':
        await _startDirectChat(user);
        break;
      case 'change_role':
        await _showRoleChangeDialog(user);
        break;
      case 'view_details':
        await _showUserDetailsDialog(user);
        break;
      case 'suspend':
        await _showSuspendUserDialog(user);
        break;
    }
  }

  Future<void> _startDirectChat(UserModel user) async {
    try {
      final chatRoom = await ChatService.getOrCreateDirectChat(user.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(chatRoomId: chatRoom.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRoleChangeDialog(UserModel user) async {
    UserRole? selectedRole = user.role;
    
    final newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current role: ${user.role.toString().split('.').last}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'New Role',
                border: OutlineInputBorder(),
              ),
              items: UserRole.values.map((role) => DropdownMenuItem(
                value: role,
                child: Text(role.toString().split('.').last),
              )).toList(),
              onChanged: (value) => selectedRole = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedRole),
            child: const Text('Change Role'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != user.role) {
      try {
        await UserService.updateUserRole(user.id, newRole);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role changed to ${newRole.toString().split('.').last}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showUserDetailsDialog(UserModel user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details: ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${user.email}'),
              Text('Role: ${user.role.toString().split('.').last}'),
              Text('Department: ${user.departmentName}'),
              Text('Campus: ${user.campusName}'),
              if (user.studentId != null) Text('Student ID: ${user.studentId}'),
              if (user.course != null) Text('Course: ${user.course}'),
              if (user.yearLevel != null) Text('Year Level: ${user.yearLevel}'),
              Text('Member of ${user.clubMemberships.length} clubs'),
              Text('Created: ${_formatDate(user.createdAt)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuspendUserDialog(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Text('Are you sure you want to suspend ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement user suspension functionality
        // await UserService.suspendUser(user.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User suspension feature coming soon'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error suspending user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDepartmentName(Department department) {
    switch (department) {
      case Department.cas:
        return 'College of Arts and Sciences';
      case Department.cbe:
        return 'College of Business and Entrepreneurship';
      case Department.coe:
        return 'College of Education';
      case Department.coeng:
        return 'College of Engineering';
      case Department.cot:
        return 'College of Technology';
      case Department.coa:
        return 'College of Agriculture';
      case Department.cof:
        return 'College of Fisheries';
      case Department.cofes:
        return 'College of Forestry and Environmental Science';
      case Department.com:
        return 'College of Medicine';
      case Department.con:
        return 'College of Nursing';
      case Department.coph:
        return 'College of Pharmacy';
  
      default:
        return 'Not specified';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadPendingApplications() async {
    setState(() => _isLoading = true);
    try {
      final applications = await UserService.getAllPendingApplications();
      if(mounted){
        setState(() {
          _pendingApplications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted){
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  void _listenForPendingContent() {
    // Potentially turn off loading indicator, but might have race conditions
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    _eventsSubscription?.cancel();
    _eventsSubscription = _eventService.getPendingEvents().listen((events) {
      if (mounted) {
        setState(() {
          _pendingEvents = List.from(events);
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    });

    _announcementsSubscription?.cancel();
    _announcementsSubscription =
        _announcementService.getPendingAnnouncements().listen((announcements) {
      if (mounted) {
        setState(() {
          _pendingAnnouncements = List.from(announcements);
          _isLoading = false; // Turn off loading indicator after the second stream loads
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading announcements: $e')),
        );
      }
    });
  }

  Future<void> _loadAllUsers() async {
    // No need to set loading here as _listenForPendingContent handles it
    try {
      final users = await UserService.getAllUsers();
      if(mounted){
        setState(() {
          _allUsers = users;
          _searchFilteredUsers = users; // Initialize with all users
        });
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _loadAnalytics() async {
    try {
      // Users
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      _totalUsers = usersSnap.size;
      _activeUsers = usersSnap.docs.where((doc) => (doc.data().containsKey('isActive') ? doc['isActive'] : true) == true).length;
      _adminCount = usersSnap.docs.where((doc) => doc['role'] == 'admin').length;
      _moderatorCount = usersSnap.docs.where((doc) => doc['role'] == 'moderator').length;
      // Clubs
      final clubsSnap = await FirebaseFirestore.instance.collection('clubs').get();
      _totalClubs = clubsSnap.size;
      _activeClubs = clubsSnap.docs.where((doc) => (doc.data().containsKey('isActive') ? doc['isActive'] : true) == true).length;
      // Applications
      final applicationsSnap = await FirebaseFirestore.instance.collection('club_applications').where('status', isEqualTo: 'pending').get();
      _pendingApplicationsCount = applicationsSnap.size;
      // Events
      final eventsSnap = await FirebaseFirestore.instance.collection('events').get();
      _totalEvents = eventsSnap.size;
      _pendingEventsCount = eventsSnap.docs.where((doc) => doc['status'] == 'pending').length;
      // Announcements
      final announcementsSnap = await FirebaseFirestore.instance.collection('announcements').get();
      _totalAnnouncements = announcementsSnap.size;
      _pendingAnnouncementsCount = announcementsSnap.docs.where((doc) => doc['status'] == 'pending').length;
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  void _viewEventDetails(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl != null) Image.network(event.imageUrl!, height: 120),
              const SizedBox(height: 8),
              Text('Description: ${event.description}'),
              const SizedBox(height: 8),
              Text('Club: ${event.clubName}'),
              const SizedBox(height: 8),
              Text('Date: ${event.startDate}'),
              const SizedBox(height: 8),
              Text('Location: ${event.location ?? "-"}'),
              const SizedBox(height: 8),
              Text('Status: ${event.statusName}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _viewAnnouncementDetails(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (announcement.imageUrl != null) Image.network(announcement.imageUrl!, height: 120),
              const SizedBox(height: 8),
              Text('Content: ${announcement.content}'),
              const SizedBox(height: 8),
              Text('Club: ${announcement.clubName}'),
              const SizedBox(height: 8),
              Text('Status: ${announcement.statusName}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDeletionRequestsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventService.getDeletionRequests(),
      builder: (context, eventSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _announcementService.getDeletionRequests(),
          builder: (context, announcementSnapshot) {
            final eventRequests = eventSnapshot.data ?? [];
            final announcementRequests = announcementSnapshot.data ?? [];
            final allRequests = [...eventRequests, ...announcementRequests];
            
            if (allRequests.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_forever, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No pending deletion requests',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allRequests.length,
              itemBuilder: (context, index) {
                final request = allRequests[index];
                return _buildDeletionRequestItem(request);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDeletionRequestItem(Map<String, dynamic> request) {
    final type = request['type'] as String;
    final itemId = request['itemId'] as String;
    final requesterId = request['requesterId'] as String;
    final reason = request['reason'] as String;
    final createdAt = request['createdAt'] as Timestamp;
    final requestId = request['id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'event' ? Icons.event : Icons.announcement,
                  color: type == 'event' ? Colors.blue : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  '${type.toUpperCase()} Deletion Request',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<UserModel?>(
              future: UserService.getCurrentUser(),
              builder: (context, snapshot) {
                final requesterName = snapshot.data?.fullName ?? 'Unknown User';
                return Text(
                  'Requested by: $requesterName',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: $reason',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Requested on: ${_formatDate(createdAt.toDate())}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectionDialog(requestId, reason),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveDeletionRequest(requestId, type),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _approveDeletionRequest(String requestId, String type) async {
    try {
      if (type == 'event') {
        await _eventService.approveDeletionRequest(requestId);
      } else {
        await _announcementService.approveDeletionRequest(requestId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletion request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving deletion request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectionDialog(String requestId, String originalReason) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Deletion Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original reason: $originalReason'),
            const SizedBox(height: 16),
            const Text('Rejection reason:'),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              _rejectDeletionRequest(requestId, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _rejectDeletionRequest(String requestId, String reason) async {
    try {
      // Try both services since we don't know the type here
      try {
        await _eventService.rejectDeletionRequest(requestId, reason);
      } catch (e) {
        await _announcementService.rejectDeletionRequest(requestId, reason);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deletion request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting deletion request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class NotificationBell extends StatelessWidget {
  final String userId;
  const NotificationBell({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.data?.docs.length ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => NotificationsPage(userId: userId),
                ));
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text('$unreadCount', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotificationsPage extends StatelessWidget {
  final String userId;
  const NotificationsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: Center(child: Text('Notifications for $userId')),
    );
  }
} 