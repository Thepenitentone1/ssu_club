import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/services/event_service.dart';
import '../../../../shared/models/event.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/cloudinary_storage_service.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Performance monitoring
class EventPerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  
  static void startTimer(String name) {
    _startTimes[name] = DateTime.now();
  }
  
  static void endTimer(String name) {
    final startTime = _startTimes[name];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      print('Event Performance: $name took ${duration.inMilliseconds}ms');
      _startTimes.remove(name);
    }
  }
}

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late TabController _tabController;
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _showOnlyUpcoming = true;
  DateTime? _selectedDate;
  final List<String> _categories = [
    'All',
    'Academic',
    'Cultural',
    'Sports',
    'Career',
    'Leadership',
    'Other'
  ];
  final TextEditingController _searchController = TextEditingController();
  String? _uploadedImageUrl;
  String? _errorMessage;
  final bool _isCreating = false;

  // Performance optimizations
  List<EventModel>? _cachedEvents;
  String? _lastCategory;
  String? _lastSearchQuery;
  bool? _lastShowOnlyUpcoming;

  @override
  void initState() {
    super.initState();
    EventPerformanceMonitor.startTimer('events_page_init');
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Remove artificial delay since we'll use real data
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        EventPerformanceMonitor.endTimer('events_page_init');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load events: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Optimized filtering with memoization
  List<EventModel> _getFilteredEvents(List<EventModel> events) {
    final searchQuery = _searchController.text.toLowerCase();
    
    // Check if we can use cached data
    if (_cachedEvents != null && 
        _lastCategory == _selectedCategory && 
        _lastSearchQuery == searchQuery &&
        _lastShowOnlyUpcoming == _showOnlyUpcoming) {
      return _cachedEvents!;
    }

    // Filter events
    List<EventModel> filtered = events.where((event) {
      final matchesSearch = event.title.toLowerCase().contains(searchQuery) ||
          event.description.toLowerCase().contains(searchQuery) ||
          (event.location?.toLowerCase().contains(searchQuery) ?? false);
      final matchesCategory = _selectedCategory == 'All' || 
          event.tags.contains(_selectedCategory);
      final matchesUpcoming = !_showOnlyUpcoming || event.isUpcoming;
      
      return matchesSearch && matchesCategory && matchesUpcoming;
    }).toList();

    // Cache the result
    _cachedEvents = filtered;
    _lastCategory = _selectedCategory;
    _lastSearchQuery = searchQuery;
    _lastShowOnlyUpcoming = _showOnlyUpcoming;

    return filtered;
  }

  void _rsvpToEvent(EventModel event) {
    // TODO: Implement RSVP functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('RSVP\'d to ${event.title}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCreateEventDialog() async {
    // Check user permissions first
    final user = await UserService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create events'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!user.isModerator && !user.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only moderators and admins can create events'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String selectedCategory = 'Academic';
    String selectedImportance = 'Normal';
    String selectedVisibility = 'Club Members'; // New field
    String? imageUrl;
    bool imageUploading = false;
    final List<String> importanceOptions = ['Normal', 'Important'];
    final List<String> visibilityOptions = ['Club Members', 'Public'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.where((cat) => cat != 'All').map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedImportance,
                  decoration: const InputDecoration(
                    labelText: 'Importance',
                    border: OutlineInputBorder(),
                  ),
                  items: importanceOptions.map((importance) {
                    return DropdownMenuItem(
                      value: importance,
                      child: Text(importance),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedImportance = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedVisibility,
                  decoration: const InputDecoration(
                    labelText: 'Visibility',
                    border: OutlineInputBorder(),
                  ),
                  items: visibilityOptions.map((visibility) {
                    return DropdownMenuItem(
                      value: visibility,
                      child: Text(visibility),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVisibility = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Event Date'),
                  subtitle: Text(selectedDate?.toString() ?? 'Select date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(startTime != null ? startTime!.format(context) : 'Select'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              startTime = picked;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(endTime != null ? endTime!.format(context) : 'Select'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              endTime = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                imageUploading
                  ? const CircularProgressIndicator()
                  : imageUrl == null
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Upload Event Image'),
                        onPressed: () async {
                          setState(() { imageUploading = true; });
                          final url = await CloudinaryStorageService.uploadImageFromGallery('events');
                          setState(() {
                            imageUrl = url;
                            imageUploading = false;
                          });
                        },
                      )
                    : Column(
                        children: [
                          Image.network(imageUrl!, height: 100),
                          TextButton(
                            onPressed: () => setState(() { imageUrl = null; }),
                            child: const Text('Remove Image'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    locationController.text.isEmpty ||
                    selectedDate == null ||
                    startTime == null ||
                    endTime == null ||
                    imageUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields and upload an image')),
                  );
                  return;
                }
                final startDateTime = DateTime(
                  selectedDate!.year, selectedDate!.month, selectedDate!.day,
                  startTime!.hour, startTime!.minute,
                );
                final endDateTime = DateTime(
                  selectedDate!.year, selectedDate!.month, selectedDate!.day,
                  endTime!.hour, endTime!.minute,
                );
                await _createEvent(
                  title: titleController.text,
                  description: descriptionController.text,
                  location: locationController.text,
                  category: selectedCategory,
                  date: selectedDate!,
                  startDateTime: startDateTime,
                  endDateTime: endDateTime,
                  importance: selectedImportance,
                  visibility: selectedVisibility,
                  imageUrl: imageUrl!,
                );
                Navigator.pop(context);
              },
              child: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createEvent({
    required String title,
    required String description,
    required String location,
    required String category,
    required DateTime date,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String importance,
    required String visibility,
    required String imageUrl,
  }) async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) return;
      
      // Map category to EventType
      EventType eventType;
      switch (category.toLowerCase()) {
        case 'academic':
          eventType = EventType.academic;
          break;
        case 'cultural':
          eventType = EventType.cultural;
          break;
        case 'sports':
          eventType = EventType.sports;
          break;
        case 'career':
          eventType = EventType.professional;
          break;
        case 'leadership':
          eventType = EventType.other;
          break;
        default:
          eventType = EventType.other;
      }

      // Map visibility to EventVisibility
      EventVisibility eventVisibility;
      switch (visibility.toLowerCase()) {
        case 'public':
          eventVisibility = EventVisibility.public;
          break;
        case 'club members':
          eventVisibility = EventVisibility.club;
          break;
        default:
          eventVisibility = EventVisibility.club;
      }
      
      final event = EventModel(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        location: location,
        imageUrl: imageUrl,
        startDate: startDateTime,
        endDate: endDateTime,
        type: eventType,
        visibility: eventVisibility,
        status: EventStatus.pending,
        clubId: 'admin', // Default club ID for admin-created events
        clubName: 'SSU Administration', // Default club name for admin-created events
        createdBy: user.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: [category],
        attendeeIds: [],
        rsvpIds: [],
        maxAttendees: 0,
        requiresRSVP: false,
        isFree: true,
      );
      
      await _eventService.createEvent(event);
      
      // Send notification to admins for public events
      if (eventVisibility == EventVisibility.public) {
        await NotificationService().sendNotificationToAdmins(
          title: 'Public Event Pending Approval',
          message: '${user.fullName} has created a public event: $title',
          type: NotificationType.publicEventPending,
          priority: NotificationPriority.high,
          data: {
            'eventId': event.id,
            'eventTitle': title,
            'creatorName': user.fullName,
          },
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareEvent(EventModel event) {
    Share.share(
      'Check out this event: ${event.title}\n${event.description}\nDate: ${DateFormat('MMM dd, yyyy').format(event.startDate)}',
      subject: 'SSU Event: ${event.title}',
    );
  }

  Future<void> _addToCalendar(EventModel event) async {
    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent(event.title)}&dates=${event.startDate.toUtc().toIso8601String()}/${event.endDate.toUtc().toIso8601String()}&details=${Uri.encodeComponent(event.description)}&location=${Uri.encodeComponent(event.location ?? '')}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _cachedEvents = null; // Clear cache
      });
    }
  }

  bool _matchesDate(DateTime eventDate, DateTime selectedDate) {
    return eventDate.year == selectedDate.year &&
        eventDate.month == selectedDate.month &&
        eventDate.day == selectedDate.day;
  }

  @override
  Widget build(BuildContext context) {
    EventPerformanceMonitor.startTimer('events_page_build');
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);
    final background = const Color(0xFFF8FAFC);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoadingWidget(),
              const SizedBox(height: 16),
              Text(
                'Loading events...',
                style: TextStyle(color: primary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _initializeData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Fetch events from Firestore directly
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'approved').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingWidget());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        final events = docs.map((doc) => EventModel.fromFirestore(doc)).toList();

        return Scaffold(
          backgroundColor: background,
          body: Column(
            children: [
              // Header Row with Professional Spacing
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      onPressed: () {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Large, Prominent Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Events',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Discover and join amazing events',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons with Better Spacing
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderActionButton(
                          icon: Icons.calendar_month,
                          tooltip: 'Filter by Date',
                          onPressed: () => _showDatePicker(context),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderActionButton(
                          icon: _showOnlyUpcoming ? Icons.upcoming : Icons.history,
                          tooltip: _showOnlyUpcoming ? 'Show All Events' : 'Show Upcoming Only',
                          onPressed: () {
                            setState(() {
                              _showOnlyUpcoming = !_showOnlyUpcoming;
                              _cachedEvents = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FutureBuilder<UserModel?>(
                          future: UserService.getCurrentUser(),
                          builder: (context, userSnapshot) {
                            final user = userSnapshot.data;
                            final canCreateEvents = user?.isModerator == true || user?.isAdmin == true;
                            if (!canCreateEvents) {
                              return const SizedBox.shrink();
                            }
                            return _buildHeaderActionButton(
                              icon: Icons.add,
                              tooltip: 'Create Event',
                              onPressed: _showCreateEventDialog,
                              isPrimary: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Enhanced Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _cachedEvents = null;
                    });
                  },
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search events, locations, or organizers...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: secondary,
                      size: 24,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Enhanced Category Filters
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildEnhancedCategoryChip(category);
                  },
                ),
              ),
              // Content Area
              Expanded(
                child: _buildEventsList(events),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? const Color(0xFF3B82F6) : Colors.white,
          size: 24,
        ),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    final primary = const Color(0xFF1E3A8A);
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(
          category,
          style: GoogleFonts.poppins(
            color: isSelected ? primary : const Color(0xFF1E3A8A),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : 'All';
            _cachedEvents = null;
          });
        },
        backgroundColor: Colors.white.withOpacity(0.9),
        selectedColor: Colors.white,
        checkmarkColor: primary,
        elevation: isSelected ? 4 : 0,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildEventsList(List<EventModel> events) {
    // Filter events based on search, category, and upcoming filters
    final filteredEvents = _getFilteredEvents(events);
    
    if (filteredEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _cachedEvents = null;
        });
        await _initializeData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isUpcoming = event.isUpcoming;
    final isToday = event.startDate.day == DateTime.now().day && 
                   event.startDate.month == DateTime.now().month && 
                   event.startDate.year == DateTime.now().year;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Image Section with Status Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: event.imageUrl ?? 'https://via.placeholder.com/400x200/3B82F6/FFFFFF?text=Event+Image',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[100]!, Colors.blue[200]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 8),
                            Text('Loading...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 48, color: Colors.white),
                            SizedBox(height: 8),
                            Text('Image not available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      event.statusName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Time Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.orange : (isUpcoming ? Colors.green : Colors.grey),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isToday ? 'TODAY' : (isUpcoming ? 'UPCOMING' : 'PAST'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Enhanced Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Type
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.typeName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Event Details Row
                  Row(
                    children: [
                      // Date & Time
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.event,
                                size: 16,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(event.startDate),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('HH:mm').format(event.startDate)} - ${DateFormat('HH:mm').format(event.endDate)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Location
                      if (event.location != null)
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bottom Row with Organizer and Actions
                  Row(
                    children: [
                      // Organizer Info
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                              child: Text(
                                event.clubName.isNotEmpty ? event.clubName[0].toUpperCase() : 'E',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Organized by',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  Text(
                                    event.clubName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Row(
                        children: [
                          // Attendees Count
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${event.attendeeCount}/${event.maxAttendees == 0 ? '∞' : event.maxAttendees}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit and Delete buttons for moderators/admins
                          FutureBuilder<UserModel?>(
                            future: UserService.getCurrentUser(),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              if (user != null && (user.isAdmin || user.canModerate(event.clubId))) {
                                return Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _showEditEventDialog(event),
                                      icon: const Icon(Icons.edit, size: 20),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.blue[100],
                                        shape: const CircleBorder(),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: () => _showDeleteEventDialog(event),
                                      icon: const Icon(Icons.delete, size: 20),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red[100],
                                        shape: const CircleBorder(),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          // Share Button
                          IconButton(
                            onPressed: () => _shareEvent(event),
                            icon: const Icon(Icons.share, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.approved:
        return Colors.green;
      case EventStatus.pending:
        return Colors.orange;
      case EventStatus.rejected:
        return Colors.red;
      case EventStatus.draft:
        return Colors.grey;
      case EventStatus.active:
        return Colors.blue;
      case EventStatus.cancelled:
        return Colors.red;
      case EventStatus.completed:
        return Colors.purple;
    }
  }

  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Enhanced Header with Image
              Container(
                height: 250,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    // Event Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: CachedNetworkImage(
                        imageUrl: event.imageUrl ?? 'https://via.placeholder.com/400x200/3B82F6/FFFFFF?text=Event+Image',
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[100]!, Colors.blue[200]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 8),
                                Text('Loading...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[300]!, Colors.grey[400]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 64, color: Colors.white),
                                SizedBox(height: 8),
                                Text('Image not available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(event.status).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          event.statusName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Close Button
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                    // Event Title Overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  event.typeName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: event.isUpcoming ? Colors.green : Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  event.isUpcoming ? 'UPCOMING' : 'TODAY',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content Section
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Description Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, color: const Color(0xFF3B82F6), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'About This Event',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Event Details Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: const Color(0xFF3B82F6), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Event Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildEnhancedDetailRow(
                            Icons.event,
                            'Date & Time',
                            '${DateFormat('EEEE, MMMM dd, yyyy').format(event.startDate)}\n${DateFormat('HH:mm').format(event.startDate)} - ${DateFormat('HH:mm').format(event.endDate)}',
                            const Color(0xFF3B82F6),
                          ),
                          if (event.location != null) ...[
                            const SizedBox(height: 12),
                            _buildEnhancedDetailRow(
                              Icons.location_on,
                              'Location',
                              event.location!,
                              Colors.green,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildEnhancedDetailRow(
                            Icons.group,
                            'Organizer',
                            event.clubName,
                            Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildEnhancedDetailRow(
                            Icons.people,
                            'Attendees',
                            '${event.attendeeCount} / ${event.maxAttendees == 0 ? 'Unlimited' : event.maxAttendees}',
                            Colors.purple,
                          ),
                          if (event.tags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.tag, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tags',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: event.tags.map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            tag,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    if (event.canRSVP)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.event_available, color: Colors.white),
                              label: Text(
                                'RSVP to Event',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _rsvpToEvent(event),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join ${event.attendeeCount} other attendees',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Additional Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _shareEvent(event),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Add to Calendar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _addToCalendar(event),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditEventDialog(EventModel event) async {
    // Check user permissions first
    final user = await UserService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to edit events'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user can edit this event
    if (!user.isAdmin && !user.canModerate(event.clubId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit events from clubs you moderate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description);
    final locationController = TextEditingController(text: event.location ?? '');
    DateTime? selectedDate = event.startDate;
    TimeOfDay? startTime = TimeOfDay.fromDateTime(event.startDate);
    TimeOfDay? endTime = TimeOfDay.fromDateTime(event.endDate);
    String selectedCategory = event.tags.isNotEmpty ? event.tags.first : 'Academic';
    String selectedImportance = 'Normal';
    String selectedVisibility = event.visibility == EventVisibility.public ? 'Public' : 'Club Members';
    String? imageUrl = event.imageUrl;
    bool imageUploading = false;
    final List<String> importanceOptions = ['Normal', 'Important'];
    final List<String> visibilityOptions = ['Club Members', 'Public'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.where((cat) => cat != 'All').map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedImportance,
                  decoration: const InputDecoration(
                    labelText: 'Importance',
                    border: OutlineInputBorder(),
                  ),
                  items: importanceOptions.map((importance) {
                    return DropdownMenuItem(
                      value: importance,
                      child: Text(importance),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedImportance = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedVisibility,
                  decoration: const InputDecoration(
                    labelText: 'Visibility',
                    border: OutlineInputBorder(),
                  ),
                  items: visibilityOptions.map((visibility) {
                    return DropdownMenuItem(
                      value: visibility,
                      child: Text(visibility),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVisibility = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Event Date'),
                  subtitle: Text(selectedDate?.toString() ?? 'Select date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(startTime != null ? startTime!.format(context) : 'Select'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              startTime = picked;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(endTime != null ? endTime!.format(context) : 'Select'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              endTime = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                imageUploading
                  ? const CircularProgressIndicator()
                  : imageUrl == null
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Upload Event Image'),
                        onPressed: () async {
                          setState(() { imageUploading = true; });
                          final url = await CloudinaryStorageService.uploadImageFromGallery('events');
                          setState(() {
                            imageUrl = url;
                            imageUploading = false;
                          });
                        },
                      )
                    : Column(
                        children: [
                          Image.network(imageUrl!, height: 100),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  setState(() { imageUploading = true; });
                                  final url = await CloudinaryStorageService.uploadImageFromGallery('events');
                                  setState(() {
                                    imageUrl = url;
                                    imageUploading = false;
                                  });
                                },
                                child: const Text('Change Image'),
                              ),
                              TextButton(
                                onPressed: () => setState(() { imageUrl = null; }),
                                child: const Text('Remove Image'),
                              ),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    locationController.text.isEmpty ||
                    selectedDate == null ||
                    startTime == null ||
                    endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }
                final startDateTime = DateTime(
                  selectedDate!.year, selectedDate!.month, selectedDate!.day,
                  startTime!.hour, startTime!.minute,
                );
                final endDateTime = DateTime(
                  selectedDate!.year, selectedDate!.month, selectedDate!.day,
                  endTime!.hour, endTime!.minute,
                );
                await _updateEvent(
                  event: event,
                  title: titleController.text,
                  description: descriptionController.text,
                  location: locationController.text,
                  category: selectedCategory,
                  date: selectedDate!,
                  startDateTime: startDateTime,
                  endDateTime: endDateTime,
                  importance: selectedImportance,
                  visibility: selectedVisibility,
                  imageUrl: imageUrl,
                );
                Navigator.pop(context);
              },
              child: const Text('Update Event'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteEventDialog(EventModel event) async {
    // Check user permissions first
    final user = await UserService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to delete events'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user can delete this event
    if (!user.isAdmin && !user.canModerate(event.clubId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete events from clubs you moderate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete "${event.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for deletion (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              if (user.isAdmin) {
                // Admin can delete directly
                await _eventService.deleteEvent(event.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Event "${event.title}" deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // Moderator needs to request deletion
                await _eventService.requestEventDeletion(
                  event.id,
                  user.id,
                  reasonController.text.isEmpty ? 'No reason provided' : reasonController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deletion request sent for "${event.title}"'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEvent({
    required EventModel event,
    required String title,
    required String description,
    required String location,
    required String category,
    required DateTime date,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String importance,
    required String visibility,
    required String? imageUrl,
  }) async {
    try {
      final user = await UserService.getCurrentUser();
      if (user == null) return;
      
      // Map visibility to EventVisibility
      EventVisibility eventVisibility;
      switch (visibility.toLowerCase()) {
        case 'public':
          eventVisibility = EventVisibility.public;
          break;
        case 'club members':
          eventVisibility = EventVisibility.club;
          break;
        default:
          eventVisibility = EventVisibility.club;
      }
      
      final eventData = {
        'title': title,
        'description': description,
        'location': location,
        'startDate': Timestamp.fromDate(startDateTime),
        'endDate': Timestamp.fromDate(endDateTime),
        'visibility': eventVisibility.toString().split('.').last,
        'updatedAt': Timestamp.now(),
        'tags': [category],
        'imageUrl': imageUrl,
      };
      
      await _eventService.updateEvent(event.id, eventData);
      
      await NotificationService().sendNotificationToAdmins(
        title: 'Event Updated',
        message: 'Event "${title}" updated by ${user.fullName}',
        type: NotificationType.eventUpdate,
        priority: NotificationPriority.normal,
        data: {'eventId': event.id},
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 