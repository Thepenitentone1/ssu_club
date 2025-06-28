import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ssu_club_hub/shared/models/club.dart';
import 'package:ssu_club_hub/core/services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:ssu_club_hub/shared/models/user.dart';
import 'package:ssu_club_hub/core/services/chat_service.dart';

// Performance monitoring
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  
  static void startTimer(String name) {
    _startTimes[name] = DateTime.now();
  }
  
  static void endTimer(String name) {
    final startTime = _startTimes[name];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      print('Performance: $name took ${duration.inMilliseconds}ms');
      _startTimes.remove(name);
    }
  }
}

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Academic',
    'Technical',
    'Cultural',
    'Sports',
    'Religious',
    'Professional',
    'Social',
    'Environmental',
    'Health',
    'Leadership',
    'Service',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _checkAndCreateSSUClubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAndCreateSSUClubs() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) return;

      final clubsRef = FirebaseFirestore.instance.collection('clubs');
      final existingClubs = await clubsRef.limit(1).get();
      
      if (existingClubs.docs.isNotEmpty) return;

      await _createAllSSUClubs();
    } catch (e) {
      print('Error checking and creating SSU clubs: $e');
    }
  }

  Future<void> _createAllSSUClubs() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) return;

      final clubsRef = FirebaseFirestore.instance.collection('clubs');

      // Create SSU student clubs and societies
      final ssuClubs = [
        {
          'name': 'I.T. Society',
          'description': 'A community for Information Technology students to share knowledge, collaborate on projects, and stay updated with the latest tech trends.',
          'type': 'technical',
          'status': 'active',
          'visibility': 'department',
          'department': 'cot',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Technology', 'Information Technology', 'Programming', 'Digital Innovation'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/system.png',
        },
        {
          'name': 'Society of English Majors',
          'description': 'Fostering excellence in English language, literature, and communication skills through academic and cultural activities.',
          'type': 'academic',
          'status': 'active',
          'visibility': 'department',
          'department': 'cas',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['English', 'Literature', 'Communication', 'Language Arts'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/eng.png',
        },
        {
          'name': 'Mathematics Society',
          'description': 'Promoting mathematical excellence, problem-solving skills, and analytical thinking through workshops and competitions.',
          'type': 'academic',
          'status': 'active',
          'visibility': 'department',
          'department': 'cas',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Mathematics', 'Problem Solving', 'Analytics', 'STEM'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/math.png',
        },
        {
          'name': 'Psychology Society',
          'description': 'Exploring human behavior, mental health awareness, and psychological research through seminars and community outreach.',
          'type': 'academic',
          'status': 'active',
          'visibility': 'department',
          'department': 'cas',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Psychology', 'Mental Health', 'Human Behavior', 'Research'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/pschy.png',
        },
        {
          'name': 'Elementary Education Society',
          'description': 'Preparing future educators through teaching workshops, child development studies, and community service projects.',
          'type': 'academic',
          'status': 'active',
          'visibility': 'department',
          'department': 'coe',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Education', 'Elementary Teaching', 'Child Development', 'Community Service'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/elem.png',
        },
        {
          'name': 'Educators Society',
          'description': 'Professional development for education students through teaching methodologies, classroom management, and educational leadership.',
          'type': 'academic',
          'status': 'active',
          'visibility': 'department',
          'department': 'coe',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Education', 'Teaching', 'Professional Development', 'Leadership'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/educators.png',
        },
        {
          'name': 'Delta Engineering Society',
          'description': 'Advancing engineering excellence through technical projects, innovation workshops, and industry collaboration.',
          'type': 'technical',
          'status': 'active',
          'visibility': 'department',
          'department': 'coeng',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Engineering', 'Technical Innovation', 'Projects', 'Industry'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/delta.png',
        },
        {
          'name': 'KAUPOD (Kapisanan ng mga Mag-aaral sa Agrikultura)',
          'description': 'Promoting agricultural excellence, sustainable farming practices, and rural development through hands-on projects.',
          'type': 'academic',
          'status': 'active',
          'visibility': 'department',
          'department': 'coa',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Agriculture', 'Sustainable Farming', 'Rural Development', 'Environmental'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/kaupod.png',
        },
        {
          'name': 'United Student Council',
          'description': 'Representing student interests, organizing campus events, and fostering student leadership and governance.',
          'type': 'leadership',
          'status': 'active',
          'visibility': 'public',
          'department': 'cas',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Student Government', 'Leadership', 'Campus Events', 'Advocacy'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/united.png',
        },
        {
          'name': 'Red Cross Youth',
          'description': 'Promoting humanitarian service, disaster preparedness, and community health through volunteer activities.',
          'type': 'service',
          'status': 'active',
          'visibility': 'public',
          'department': 'cas',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Humanitarian', 'Disaster Preparedness', 'Community Service', 'Health'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/redcross.png',
        },
        {
          'name': 'Campus Ministry',
          'description': 'Fostering spiritual growth, religious activities, and interfaith dialogue within the university community.',
          'type': 'religious',
          'status': 'active',
          'visibility': 'public',
          'department': 'cas',
          'campus': 'main',
          'createdBy': currentUser.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'tags': ['Spiritual', 'Religious Activities', 'Interfaith', 'Community'],
          'memberIds': [],
          'moderatorIds': [],
          'adminIds': [],
          'settings': {},
          'requiresApproval': true,
          'isPublicContentApproved': true,
          'memberCount': 0,
          'eventCount': 0,
          'announcementCount': 0,
          'logoUrl': 'assets/images/clubs/ministry.png',
        },
      ];

      // Add clubs to Firestore
      for (final clubData in ssuClubs) {
        final docRef = await clubsRef.add(clubData);
        
        // Create chat room for the club
        try {
          await ChatService.createClubChatRoom(docRef.id);
        } catch (e) {
          print('Error creating chat room for club ${clubData['name']}: $e');
        }
      }

      print('Successfully created ${ssuClubs.length} SSU student clubs and societies!');
      setState(() {}); // Refresh the UI
    } catch (e) {
      print('Error creating SSU clubs: $e');
    }
  }

  IconData _getClubIcon(ClubType type) {
    switch (type) {
      case ClubType.academic:
        return Icons.school;
      case ClubType.cultural:
        return Icons.palette;
      case ClubType.sports:
        return Icons.sports_basketball;
      case ClubType.religious:
        return Icons.church;
      case ClubType.professional:
        return Icons.work;
      case ClubType.social:
        return Icons.people;
      case ClubType.technical:
        return Icons.computer;
      case ClubType.environmental:
        return Icons.eco;
      case ClubType.health:
        return Icons.health_and_safety;
      case ClubType.leadership:
        return Icons.leaderboard;
      case ClubType.service:
        return Icons.volunteer_activism;
      case ClubType.other:
        return Icons.groups;
      default:
        return Icons.groups;
    }
  }

  Stream<QuerySnapshot> _getClubsStream() {
    // First try to get active clubs, if none found, get all clubs
    return FirebaseFirestore.instance
        .collection('clubs')
        .snapshots();
  }

  List<ClubModel> _filterAndSortClubs(List<ClubModel> allClubs, UserModel? user) {
    // Remove duplicate clubs by id and name (case-insensitive)
    final uniqueClubs = <String, ClubModel>{};
    final seenNames = <String>{};
    for (final club in allClubs) {
      final nameKey = (club.name ?? '').trim().toLowerCase();
      if (!uniqueClubs.containsKey(club.id) && !seenNames.contains(nameKey)) {
        uniqueClubs[club.id] = club;
        seenNames.add(nameKey);
      }
    }
    final filteredClubs = uniqueClubs.values.where((club) {
      final matchesCategory = _selectedCategory == 'All' ||
          (club.typeName ?? '') == _selectedCategory;
      final matchesSearch = _searchController.text.isEmpty ||
          (club.name ?? '').toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (club.description ?? '').toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Sort clubs based on relevance to user
    if (user != null && user.department != null) {
      filteredClubs.sort((a, b) {
        // First priority: Active clubs
        final aIsActive = a.isActive;
        final bIsActive = b.isActive;
        
        if (aIsActive && !bIsActive) return -1;
        if (!aIsActive && bIsActive) return 1;
        
        // Second priority: Clubs from user's department
        final aIsUserDepartment = a.department == user.department;
        final bIsUserDepartment = b.department == user.department;
        
        if (aIsUserDepartment && !bIsUserDepartment) return -1;
        if (!aIsUserDepartment && bIsUserDepartment) return 1;
        
        // Third priority: Public clubs
        final aIsPublic = a.isPublic;
        final bIsPublic = b.isPublic;
        
        if (aIsPublic && !bIsPublic) return -1;
        if (!aIsPublic && bIsPublic) return 1;
        
        // Fourth priority: Alphabetical by name
        return a.name.compareTo(b.name);
      });
    } else {
      // If no user, just sort by active status and name
      filteredClubs.sort((a, b) {
        final aIsActive = a.isActive;
        final bIsActive = b.isActive;
        
        if (aIsActive && !bIsActive) return -1;
        if (!aIsActive && bIsActive) return 1;
        
        return a.name.compareTo(b.name);
      });
    }

    return filteredClubs;
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(primary, secondary),
            _buildCategoryFilters(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getClubsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Clubs error: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LoadingWidget());
                  }

                  final allClubs = snapshot.data!.docs
                      .map((doc) => ClubModel.fromFirestore(doc))
                      .toList();

                  print('Found ${allClubs.length} clubs in database');

                  return FutureBuilder<UserModel?>(
                    future: UserService.getCurrentUser(),
                    builder: (context, userSnapshot) {
                      final user = userSnapshot.data;
                      final filteredClubs = _filterAndSortClubs(allClubs, user);

                      print('After filtering: ${filteredClubs.length} clubs');

                      if (filteredClubs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No clubs found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Clubs will appear here once they are created',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredClubs.length,
                        itemBuilder: (context, index) {
                          final club = filteredClubs[index];
                          return _buildClubCard(club);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary, Color secondary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Your Community',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore student organizations and clubs',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder<UserModel?>(
                future: UserService.getCurrentUser(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user?.isAdmin == true) {
                    return IconButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Create All SSU Clubs'),
                            content: const Text(
                              'This will create all SSU student clubs and societies. This action cannot be undone. Continue?'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Create'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          await _createAllSSUClubs();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All SSU clubs created successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Create All SSU Clubs',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search for clubs...',
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFF1E3A8A).withOpacity(0.8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildClubCard(ClubModel club) {
    return FutureBuilder<UserModel?>(
      future: UserService.getCurrentUser(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isUserDepartment = user?.department != null && club.department == user!.department;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _showClubDetails(context, club),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        child: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: club.logoUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      _getClubIcon(club.type ?? ClubType.other),
                                      color: Colors.grey[600],
                                      size: 24,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      _getClubIcon(club.type ?? ClubType.other),
                                      color: Colors.grey[600],
                                      size: 24,
                                    ),
                                  ),
                                ),
                              )
                            : Icon(
                                _getClubIcon(club.type ?? ClubType.other),
                                color: Colors.grey[600],
                                size: 24,
                              ),
                      ),
                      if (isUserDepartment)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                club.name ?? 'Unnamed Club',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            if (!(club.isActive ?? true))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          club.description ?? 'No description available',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClubDetails(BuildContext context, ClubModel club) {
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);
    final accentColor = club.settings['color'] != null ? Color(int.tryParse(club.settings['color'].toString()) ?? 0xFF2563EB) : primary;
    final facebook = club.settings['facebook'] as String?;
    final website = club.settings['website'] as String?;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return FutureBuilder<UserModel?>(
            future: UserService.getCurrentUser(),
            builder: (context, userSnapshot) {
              final user = userSnapshot.data;
              ClubMembership? membership;
              MembershipStatus? status;
              if (user != null) {
                membership = user.getClubMembership(club.id);
                status = membership?.status;
              }
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(0),
                  children: [
                    // Club logo and name
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8),
                      child: Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: accentColor.withOpacity(0.08),
                              backgroundImage: (club.logoUrl != null && club.logoUrl!.isNotEmpty)
                                  ? CachedNetworkImageProvider(club.logoUrl!)
                                  : null,
                              child: (club.logoUrl == null || club.logoUrl!.isEmpty)
                                  ? Icon(Icons.groups, size: 48, color: accentColor)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              club.name ?? 'No Name',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(club.typeName ?? 'Unknown'),
                              backgroundColor: accentColor.withOpacity(0.13),
                              labelStyle: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // About Section
                          const SizedBox(height: 16),
                          Text('About', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(club.description ?? 'No description available', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          // Links Section
                          if (facebook != null || website != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Links', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: accentColor)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (facebook != null)
                                      IconButton(
                                        icon: Icon(Icons.facebook, color: accentColor, size: 28),
                                        tooltip: 'Facebook Page',
                                        onPressed: () async {
                                          if (await canLaunchUrl(Uri.parse(facebook))) {
                                            await launchUrl(Uri.parse(facebook), mode: LaunchMode.externalApplication);
                                          }
                                        },
                                      ),
                                    if (website != null)
                                      IconButton(
                                        icon: Icon(Icons.link, color: accentColor, size: 28),
                                        tooltip: 'Website',
                                        onPressed: () async {
                                          if (await canLaunchUrl(Uri.parse(website))) {
                                            await launchUrl(Uri.parse(website), mode: LaunchMode.externalApplication);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          // Membership Status/Action
                          if (status == MembershipStatus.pending)
                            const Chip(label: Text('Application Pending'), backgroundColor: Colors.orangeAccent),
                          if (status == MembershipStatus.rejected)
                            const Chip(label: Text('Application Rejected'), backgroundColor: Colors.redAccent),
                          if (status == MembershipStatus.member)
                            const Chip(label: Text('You are a Member'), backgroundColor: Colors.greenAccent),
                          if (user != null && (status == null))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.group_add),
                                label: const Text('Apply to Join'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  try {
                                    await UserService.applyToJoinClub(clubId: club.id, clubName: club.name ?? '');
                                    Navigator.pop(context); // Close modal
                                    // Navigate to profile page
                                    Navigator.of(context, rootNavigator: true).pushReplacementNamed('/profile');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Application submitted! Check your profile for status.')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${e.toString()}')),
                                    );
                                  }
                                },
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Officers Section
                          Text('Officers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: accentColor)),
                          const SizedBox(height: 8),
                          _buildOfficersSectionSafe(club),
                          const SizedBox(height: 16),
                          // Members Section (preview)
                          Text('Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: accentColor)),
                          const SizedBox(height: 8),
                          _buildMembersPreviewSectionSafe(club),
                          const SizedBox(height: 16),
                          // Tags
                          if (club.tags.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tags', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: accentColor)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: club.tags.map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      backgroundColor: accentColor.withOpacity(0.1),
                                      labelStyle: TextStyle(color: accentColor),
                                      avatar: Icon(Icons.tag, size: 16, color: accentColor),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          // ... existing club info, events, announcements ...
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Null-safe officers section
  Widget _buildOfficersSectionSafe(ClubModel club) {
    final officersData = (club.settings['officers'] as List<dynamic>?) ?? [];
    if (officersData.isEmpty) {
      return const Text('No officers listed.', style: TextStyle(color: Colors.grey));
    }
    final officers = officersData.map((e) {
      try {
        return ClubOfficer.fromMap(Map<String, dynamic>.from(e));
      } catch (_) {
        return ClubOfficer(name: '', position: '', imageUrl: null, contactInfo: null);
      }
    }).toList();
    final president = officers.firstWhere(
      (o) => (o.position ?? '').toLowerCase().contains('president'),
      orElse: () => ClubOfficer(name: '', position: '', imageUrl: null, contactInfo: null),
    );
    final otherOfficers = officers.where((o) => !(o.position ?? '').toLowerCase().contains('president')).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (president.name.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.verified_user, color: Colors.amber),
            title: Text('President: ${president.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(president.contactInfo ?? ''),
          ),
        ...otherOfficers.map((officer) => ListTile(
          leading: const Icon(Icons.person, color: Colors.blueGrey),
          title: Text('${officer.position ?? ''}: ${officer.name ?? ''}'),
          subtitle: (officer.contactInfo != null && officer.contactInfo!.isNotEmpty) ? Text(officer.contactInfo!) : null,
        )),
      ],
    );
  }

  // Null-safe members preview section
  Widget _buildMembersPreviewSectionSafe(ClubModel club) {
    return FutureBuilder<List<UserModel>>(
      future: UserService.getClubMembers(club.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No members found.', style: TextStyle(color: Colors.grey));
        }
        final members = snapshot.data!;
        final preview = members.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...preview.map((member) => ListTile(
              leading: CircleAvatar(
                backgroundImage: member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty ? NetworkImage(member.profileImageUrl!) : null,
                child: (member.profileImageUrl == null || member.profileImageUrl!.isEmpty) ? Text(member.initials) : null,
              ),
              title: Text(member.fullName ?? ''),
              subtitle: Text(member.email ?? ''),
            )),
            if (members.length > 5)
              TextButton(
                onPressed: () {
                  // TODO: Show all members in a dialog or new page
                },
                child: const Text('See all'),
              ),
          ],
        );
      },
    );
  }
}

class _SliverSearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverSearchDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 120;

  @override
  bool shouldRebuild(covariant _SliverSearchDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

class ClubDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> club;

  const ClubDetailsSheet({super.key, required this.club});

  @override
  State<ClubDetailsSheet> createState() => _ClubDetailsSheetState();
}

class _ClubDetailsSheetState extends State<ClubDetailsSheet> {
  bool _isJoined = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkJoinStatus();
  }

  Future<void> _checkJoinStatus() async {
    // Simulate checking if user is already a member
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isJoined = false; // This would be checked against Firestore
    });
  }

  Future<void> _toggleJoinStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isJoined = !_isJoined;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isJoined ? 'Successfully joined ${widget.club['name']}!' : 'Left ${widget.club['name']}'),
          backgroundColor: _isJoined ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openFacebookPage() async {
    final url = widget.club['facebook'];
    if (url != null) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Facebook page: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareClub() async {
    try {
      await Share.share(
        'Check out ${widget.club['name']} at SSU! ${widget.club['description']}',
        subject: 'SSU Club: ${widget.club['name']}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.club['color'].withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.club['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.group, size: 32, color: widget.club['color']),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.club['name'],
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.group, size: 16, color: widget.club['color']),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.club['members']} members',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: widget.club['color'],
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 24, color: widget.club['color']),
                    ),
                  ],
                ),
                
                // Action buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _toggleJoinStatus,
                        icon: _isLoading 
                            ? const SmallLoadingWidget(size: 16, color: Colors.white)
                            : Icon(_isJoined ? Icons.exit_to_app : Icons.group_add),
                        label: Text(_isJoined ? 'Leave Club' : 'Join Club'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isJoined ? Colors.red : widget.club['color'],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _openFacebookPage,
                      icon: Icon(Icons.facebook, color: widget.club['color']),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.club['color'].withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _shareClub,
                      icon: Icon(Icons.share, color: widget.club['color']),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.club['color'].withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About section
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.club['description'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.club['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.club['color'].withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.club['typeName'],
                      style: TextStyle(
                        color: widget.club['color'],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tags
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (widget.club['tags'] as List<String>).map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: widget.club['color'].withOpacity(0.1),
                        labelStyle: TextStyle(color: widget.club['color']),
                        avatar: Icon(Icons.tag, size: 16, color: widget.club['color']),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Announcements
                  Text(
                    'Recent Announcements',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...(widget.club['announcements'] as List<Map<String, dynamic>>).map((announcement) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.club['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.announcement, size: 20, color: widget.club['color']),
                        ),
                        title: Text(
                          announcement['title'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          announcement['date'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: widget.club['color']),
                        onTap: () {
                          // TODO: Show announcement details
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Viewing: ${announcement['title']}'),
                              backgroundColor: widget.club['color'],
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                  
                  // Events
                  Text(
                    'Upcoming Events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...(widget.club['events'] as List<Map<String, dynamic>>).map((event) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.club['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.event, size: 20, color: widget.club['color']),
                        ),
                        title: Text(
                          event['title'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          event['date'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: widget.club['color']),
                        onTap: () {
                          // TODO: Show event details
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Viewing: ${event['title']}'),
                              backgroundColor: widget.club['color'],
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateClubSheet extends StatelessWidget {
  const CreateClubSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(
                  'Create New Club',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: primary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Club Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: secondary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: secondary, width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Facebook Page URL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: secondary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: secondary, width: 2),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'academic', child: Text('Academic')),
                    DropdownMenuItem(value: 'cultural', child: Text('Cultural')),
                    DropdownMenuItem(value: 'sports', child: Text('Sports')),
                    DropdownMenuItem(value: 'religious', child: Text('Religious')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondary, primary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: secondary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Club creation request submitted'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: secondary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Submit for Approval',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 