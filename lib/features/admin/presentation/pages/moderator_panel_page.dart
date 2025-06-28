import 'package:flutter/material.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/models/club.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/models/announcement.dart';
import '../../../../core/services/user_service.dart';
import '../../../events/data/services/event_service.dart';
import '../../../announcements/data/services/announcement_service.dart';
import '../../../../shared/widgets/loading_widget.dart';

class ModeratorPanelPage extends StatefulWidget {
  const ModeratorPanelPage({super.key});

  @override
  State<ModeratorPanelPage> createState() => _ModeratorPanelPageState();
}

class _ModeratorPanelPageState extends State<ModeratorPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _currentUser;
  List<ClubApplication> _pendingApplications = [];
  List<ClubModel> _moderatedClubs = [];
  List<EventModel> _pendingEvents = [];
  List<AnnouncementModel> _pendingAnnouncements = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCurrentUser();
    _loadModeratedClubs();
    _loadPendingApplications();
    _loadPendingEvents();
    _loadPendingAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await UserService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadModeratedClubs() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      final clubIds = _currentUser!.getModeratedClubIds();
      final clubs = <ClubModel>[];
      
      for (final clubId in clubIds) {
        final club = await UserService.getClub(clubId);
        if (club != null) {
          clubs.add(club);
        }
      }

      setState(() {
        _moderatedClubs = clubs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading clubs: $e')),
      );
    }
  }

  Future<void> _loadPendingApplications() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      final applications = await UserService.getPendingApplications();
      setState(() {
        _pendingApplications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading applications: $e')),
      );
    }
  }

  Future<void> _loadPendingEvents() async {
    if (_moderatedClubs.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final eventService = EventService();
      final allPendingEvents = <EventModel>[];

      for (final club in _moderatedClubs) {
        final events = await eventService.getPendingEventsByClub(club.id).first;
        allPendingEvents.addAll(events);
      }

      setState(() {
        _pendingEvents = allPendingEvents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pending events: $e')),
      );
    }
  }

  Future<void> _loadPendingAnnouncements() async {
    if (_moderatedClubs.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final announcementService = AnnouncementService();
      final allPendingAnnouncements = <AnnouncementModel>[];

      for (final club in _moderatedClubs) {
        final announcements = await announcementService.getPendingAnnouncementsByClub(club.id).first;
        allPendingAnnouncements.addAll(announcements);
      }

      setState(() {
        _pendingAnnouncements = allPendingAnnouncements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pending announcements: $e')),
      );
    }
  }

  Future<void> _approveApplication(ClubApplication application) async {
    try {
      await UserService.approveClubApplication(
        applicationId: application.id,
        userId: application.userId,
        clubId: application.clubId,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application approved successfully')),
      );
      
      _loadPendingApplications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving application: $e')),
      );
    }
  }

  Future<void> _rejectApplication(ClubApplication application) async {
    final reason = await _showRejectionDialog();
    if (reason != null) {
      try {
        await UserService.rejectClubApplication(
          applicationId: application.id,
          userId: application.userId,
          clubId: application.clubId,
          reason: reason,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application rejected')),
        );
        
        _loadPendingApplications();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting application: $e')),
        );
      }
    }
  }

  Future<String?> _showRejectionDialog({String title = 'Reject Application'}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason',
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
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationTile(ClubApplication application) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      ? Text(application.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        application.userEmail,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (application.message != null) ...[
              const SizedBox(height: 12),
              Text(
                'Message:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(application.message!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Applied: ${_formatDate(application.appliedAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _rejectApplication(application),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveApplication(application),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubTile(ClubModel club) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: club.logoUrl != null
              ? NetworkImage(club.logoUrl!)
              : null,
          child: club.logoUrl == null
              ? Text(club.name[0].toUpperCase())
              : null,
        ),
        title: Text(
          club.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(club.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${club.memberCount} members'),
                const SizedBox(width: 16),
                Icon(Icons.admin_panel_settings, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${club.moderatorIds.length} moderators'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'members':
                _showClubMembers(club);
                break;
              case 'settings':
                _showClubSettings(club);
                break;
              case 'events':
                _showClubEvents(club);
                break;
              case 'announcements':
                _showClubAnnouncements(club);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'members',
              child: Row(
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 8),
                  Text('Manage Members'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Club Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'events',
              child: Row(
                children: [
                  Icon(Icons.event),
                  SizedBox(width: 8),
                  Text('Manage Events'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'announcements',
              child: Row(
                children: [
                  Icon(Icons.announcement),
                  SizedBox(width: 8),
                  Text('Manage Announcements'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClubMembers(ClubModel club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${club.name} Members'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<UserModel>>(
            future: UserService.getClubMembers(club.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingWidget());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading members: ${snapshot.error}'),
                );
              }

              final members = snapshot.data ?? [];
              
              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.profileImageUrl != null
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                      child: member.profileImageUrl == null
                          ? Text(member.initials)
                          : null,
                    ),
                    title: Text(member.fullName),
                    subtitle: Text(member.email),
                    trailing: club.moderatorIds.contains(member.id)
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Moderator',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              );
            },
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

  void _showClubSettings(ClubModel club) {
    // Implement club settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Club settings feature coming soon')),
    );
  }

  void _showClubEvents(ClubModel club) {
    // Implement club events management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Events management feature coming soon')),
    );
  }

  void _showClubAnnouncements(ClubModel club) {
    // Implement club announcements management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcements management feature coming soon')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderator Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Applications', icon: Icon(Icons.person_add)),
            Tab(text: 'My Clubs', icon: Icon(Icons.groups)),
            Tab(text: 'Events', icon: Icon(Icons.event)),
            Tab(text: 'Announcements', icon: Icon(Icons.announcement)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Applications Tab
          _isLoading
              ? const Center(child: LoadingWidget())
              : _pendingApplications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No pending applications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All applications have been processed',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pendingApplications.length,
                      itemBuilder: (context, index) {
                        return _buildApplicationTile(_pendingApplications[index]);
                      },
                    ),

          // My Clubs Tab
          _isLoading
              ? const Center(child: LoadingWidget())
              : _moderatedClubs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No moderated clubs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You are not a moderator of any clubs',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _moderatedClubs.length,
                      itemBuilder: (context, index) {
                        return _buildClubTile(_moderatedClubs[index]);
                      },
                    ),

          // Events Tab
          _isLoading
              ? const Center(child: LoadingWidget())
              : _pendingEvents.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No pending events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All events have been processed',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pendingEvents.length,
                      itemBuilder: (context, index) {
                        return _buildEventTile(_pendingEvents[index]);
                      },
                    ),

          // Announcements Tab
          _isLoading
              ? const Center(child: LoadingWidget())
              : _pendingAnnouncements.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No pending announcements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All announcements have been processed',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pendingAnnouncements.length,
                      itemBuilder: (context, index) {
                        return _buildAnnouncementTile(_pendingAnnouncements[index]);
                      },
                    ),
        ],
      ),
    );
  }

  Future<void> _approveEvent(EventModel event) async {
    final eventService = EventService();
    try {
      await eventService.updateEvent(event.id, {'visibility': 'public', 'status': 'pending'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event submitted for admin review'), backgroundColor: Colors.blue),
      );
      _loadPendingEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving event: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectEvent(EventModel event) async {
    final reason = await _showRejectionDialog(title: 'Reject Event');
    if (reason != null) {
      final eventService = EventService();
      try {
        await eventService.updateEvent(event.id, {'status': 'rejected', 'rejectionReason': reason});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event rejected'), backgroundColor: Colors.orange),
        );
        _loadPendingEvents();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting event: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEventTile(EventModel event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Club: ${event.clubName}'),
            Text('Date: ${_formatDate(event.startDate)}'),
            Text('Location: ${event.location ?? 'TBD'}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _rejectEvent(event),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveEvent(event),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveAnnouncement(AnnouncementModel announcement) async {
    final announcementService = AnnouncementService();
    try {
      await announcementService.updateAnnouncement(announcement.id, {'visibility': 'public', 'status': 'pending'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement submitted for admin review'), backgroundColor: Colors.blue),
      );
      _loadPendingAnnouncements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving announcement: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectAnnouncement(AnnouncementModel announcement) async {
    final reason = await _showRejectionDialog(title: 'Reject Announcement');
    if (reason != null) {
      final announcementService = AnnouncementService();
      try {
        await announcementService.updateAnnouncement(announcement.id, {'status': 'rejected', 'rejectionReason': reason});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement rejected'), backgroundColor: Colors.orange),
        );
        _loadPendingAnnouncements();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting announcement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAnnouncementTile(AnnouncementModel announcement) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Club: ${announcement.clubName}'),
            const SizedBox(height: 4),
            Text(
              announcement.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _rejectAnnouncement(announcement),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveAnnouncement(announcement),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 