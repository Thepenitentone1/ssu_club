import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/cloudinary_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/services/announcement_service.dart';
import '../../../../shared/models/announcement.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/services/user_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> with SingleTickerProviderStateMixin {
  final AnnouncementService _announcementService = AnnouncementService();
  late TabController _tabController;
  String _selectedCategory = 'All';
  final bool _showOnlyUnread = false;
  final bool _showOnlyPinned = false;
  DateTime? _selectedDate;
  final Set<String> _readAnnouncements = {};
  final Set<String> _savedAnnouncements = {};
  final TextEditingController _searchController = TextEditingController();
  String? _uploadedImageUrl;
  bool _isLoading = true;
  final bool _isCreating = false;
  String? _errorMessage;
  Timer? _searchDebounceTimer; // Add debounce timer

  // Performance optimizations
  List<AnnouncementModel>? _cachedAnnouncements;
  String? _lastCategory;
  String? _lastSearchQuery;
  bool? _lastShowOnlyUnread;
  bool? _lastShowOnlyPinned;

  final List<String> _categories = ['All', 'Academic', 'Research', 'Administrative', 'Student Life', 'Events', 'Important'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Clear any existing cache
      _cachedAnnouncements = null;
      
      // Set loading to false immediately since we're using StreamBuilder
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load announcements: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel(); // Cancel timer
    super.dispose();
  }

  void _markAsRead(String announcementId) {
    setState(() {
      _readAnnouncements.add(announcementId);
      _cachedAnnouncements = null; // Clear cache
    });
  }

  void _toggleSaved(String announcementId) {
    setState(() {
      if (_savedAnnouncements.contains(announcementId)) {
        _savedAnnouncements.remove(announcementId);
      } else {
        _savedAnnouncements.add(announcementId);
      }
    });
  }

  Future<void> _shareAnnouncement(AnnouncementModel announcement) async {
    final text = '${announcement.title}\n\n${announcement.content}\n\nShared from SSU Club Hub';
    await Share.share(text);
  }

  void _showCreateAnnouncementDialog() async {
    // Check user permissions first
    final user = await UserService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create announcements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!user.isModerator && !user.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only moderators and admins can create announcements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCategory = 'Academic';
    String selectedPriority = 'Normal';
    String selectedVisibility = 'Club Members'; // Default to club members for moderators
    bool isImportant = false;
    bool isPinned = false;
    String? imageUrl;
    bool imageUploading = false;
    DateTime? startDate;
    DateTime? endDate;
    final List<String> priorityOptions = ['Normal', 'Important', 'Urgent'];
    final List<String> visibilityOptions = ['Club Members', 'Public'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced Image Upload Section
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                  ),
                  child: imageUploading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Uploading image...'),
                          ],
                        ),
                      )
                    : imageUrl != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl!,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: () => setState(() { imageUrl = null; }),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _handleImageUpload(
                                setState, 
                                (url) => imageUrl = url, 
                                (state) => imageUploading = state
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Title Field
                TextField(
                  controller: titleController,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Announcement Title *',
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                // Content Field
                TextField(
                  controller: contentController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Content *',
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                // Category and Priority Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: _categories.where((cat) => cat != 'All').map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category, style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.priority_high),
                        ),
                        items: priorityOptions.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority, style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPriority = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Visibility Dropdown
                DropdownButtonFormField<String>(
                  value: selectedVisibility,
                  decoration: InputDecoration(
                    labelText: 'Visibility',
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.visibility),
                  ),
                  items: visibilityOptions.map((visibility) {
                    return DropdownMenuItem(
                      value: visibility,
                      child: Text(visibility, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVisibility = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Date Range Fields
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                startDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    startDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(startDate!)
                                      : 'Start Date (Optional)',
                                    style: GoogleFonts.poppins(
                                      color: startDate != null ? Colors.black87 : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? (startDate ?? DateTime.now()),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                endDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    endDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(endDate!)
                                      : 'End Date (Optional)',
                                    style: GoogleFonts.poppins(
                                      color: endDate != null ? Colors.black87 : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Checkboxes for Important and Pinned
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Mark as Important', style: GoogleFonts.poppins(fontSize: 14)),
                        value: isImportant,
                        onChanged: (value) {
                          setState(() {
                            isImportant = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Pin Announcement', style: GoogleFonts.poppins(fontSize: 14)),
                        value: isPinned,
                        onChanged: (value) {
                          setState(() {
                            isPinned = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Show loading state
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Creating announcement...'),
                    ],
                  ),
                ),
              );

              try {
                // Get user data once and cache it
                final user = await UserService.getCurrentUser();
                if (user == null) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to create announcements'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Pre-process data to avoid repeated calculations
                final importance = selectedPriority == 'Important' || selectedPriority == 'Urgent';
                final status = selectedVisibility == 'Public' ? 'pending' : 'approved';
                final isPublic = selectedVisibility == 'Public';

                // Create announcement data efficiently
                final announcementData = {
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                  'type': selectedCategory.toLowerCase(),
                  'clubId': 'admin',
                  'clubName': 'SSU Administration',
                  'createdBy': user.id,
                  'createdAt': Timestamp.now(),
                  'updatedAt': Timestamp.now(),
                  'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
                  'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
                  'tags': [selectedCategory],
                  'visibility': selectedVisibility.toLowerCase(),
                  'status': status,
                  'isImportant': importance || isImportant,
                  'isPinned': isPinned,
                  'imageUrl': imageUrl,
                  'readByIds': [],
                  'importantForIds': [],
                };

                // Create announcement in Firestore
                final docRef = await FirebaseFirestore.instance
                    .collection('announcements')
                    .add(announcementData);

                // Send notification asynchronously without waiting
                if (isPublic) {
                  // Fire and forget notification to avoid blocking
                  NotificationService().sendNotificationToAdmins(
                    title: 'Public Announcement Pending Approval',
                    message: '${user.fullName} has created a public announcement: ${titleController.text}',
                    type: NotificationType.publicAnnouncementPending,
                    priority: NotificationPriority.high,
                    data: {
                      'announcementId': docRef.id,
                      'announcementTitle': titleController.text,
                      'creatorName': user.fullName,
                    },
                  ).catchError((error) {
                    // Log error but don't block the UI
                    print('Notification error: $error');
                  });
                }

                // Close loading dialog and show success
                Navigator.pop(context); // Close loading dialog
                Navigator.pop(context); // Close create dialog
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isPublic 
                      ? 'Announcement created successfully! Pending admin approval.'
                      : 'Announcement created successfully!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating announcement: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Create Announcement',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to handle image upload safely
  Future<void> _handleImageUpload(Function setState, Function(String?) updateImageUrl, Function(bool) updateUploadingState) async {
    // Safety check to ensure we're in a valid context
    if (!context.mounted) return;
    
    updateUploadingState(true);
    
    try {
      // Show upload progress
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading image...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      final url = await CloudinaryStorageService.uploadImageFromGallery('announcements');
      
      // Check if context is still valid before updating state
      if (context.mounted) {
        setState(() {
          updateImageUrl(url);
          updateUploadingState(false);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Check if context is still valid before updating state
      if (context.mounted) {
        setState(() { 
          updateUploadingState(false);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          'Tap to upload announcement image',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
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
        _cachedAnnouncements = null; // Clear cache
      });
    }
  }

  bool _matchesDate(String dateString, DateTime selectedDate) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateString);
      return date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
    } catch (e) {
      return false;
    }
  }

  // Optimized filtering with memoization
  List<AnnouncementModel> _getFilteredAnnouncements(List<AnnouncementModel> announcements) {
    final searchQuery = _searchController.text.toLowerCase();
    
    // Check if we can use cached data
    if (_cachedAnnouncements != null && 
        _lastCategory == _selectedCategory && 
        _lastSearchQuery == searchQuery &&
        _lastShowOnlyUnread == _showOnlyUnread &&
        _lastShowOnlyPinned == _showOnlyPinned) {
      return _cachedAnnouncements!;
    }

    // Filter announcements with proper null checks
    List<AnnouncementModel> filtered = announcements.where((announcement) {
      try {
        final matchesSearch = announcement.title.toLowerCase().contains(searchQuery) ||
            announcement.content.toLowerCase().contains(searchQuery) ||
            (announcement.clubName.isNotEmpty && announcement.clubName.toLowerCase().contains(searchQuery));
        
        final matchesCategory = _selectedCategory == 'All' || 
            (announcement.tags.isNotEmpty && announcement.tags.contains(_selectedCategory));
        
        final matchesUnread = !_showOnlyUnread || !_readAnnouncements.contains(announcement.id);
        final matchesPinned = !_showOnlyPinned || announcement.isPinned;
        
        return matchesSearch && matchesCategory && matchesUnread && matchesPinned;
      } catch (e) {
        // If there's any error in filtering, include the announcement to be safe
        print('Error filtering announcement ${announcement.id}: $e');
        return true;
      }
    }).toList();

    // Cache the result
    _cachedAnnouncements = filtered;
    _lastCategory = _selectedCategory;
    _lastSearchQuery = searchQuery;
    _lastShowOnlyUnread = _showOnlyUnread;
    _lastShowOnlyPinned = _showOnlyPinned;

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
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
                'Loading announcements...',
                style: GoogleFonts.poppins(
                  color: primary,
                  fontSize: 16,
                ),
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
                style: GoogleFonts.poppins(
                  color: primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
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

    // Fetch announcements from Firestore directly
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .where('status', isEqualTo: 'approved')
          .where('visibility', isEqualTo: 'public')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingWidget());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final docs = snapshot.data?.docs ?? [];
        List<AnnouncementModel> announcements = [];
        
        try {
          announcements = docs.map((doc) {
            try {
              return AnnouncementModel.fromFirestore(doc);
            } catch (e) {
              print('Error parsing announcement document ${doc.id}: $e');
              // Return a default announcement to prevent crashes
              return AnnouncementModel(
                id: doc.id,
                title: 'Error Loading Announcement',
                content: 'This announcement could not be loaded properly.',
                type: AnnouncementType.general,
                clubId: '',
                clubName: 'System',
                createdBy: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                tags: [],
                readByIds: [],
                importantForIds: [],
                isImportant: false,
                isPinned: false,
              );
            }
          }).toList();
        } catch (e) {
          print('Error processing announcements: $e');
          announcements = [];
        }

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: Column(
              children: [
                // Professional Header Design
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
                        color: primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.announcement,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Announcements',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Stay updated with latest news',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final user = await UserService.getCurrentUser();
                              if (user != null && (user.isModerator || user.isAdmin)) {
                                _showCreateAnnouncementDialog();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Only moderators and admins can create announcements'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
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
                            // Cancel previous timer
                            _searchDebounceTimer?.cancel();
                            
                            // Set new timer for debouncing
                            _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                setState(() {
                                  _cachedAnnouncements = null;
                                });
                              }
                            });
                          },
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search announcements, authors, or content...',
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
                    ],
                  ),
                ),
                
                // Content Area - Simplified without tabs for now
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildAnnouncementsList(announcements);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          if (selected != _selectedCategory) {
            setState(() {
              _selectedCategory = selected ? category : 'All';
              _cachedAnnouncements = null;
            });
          }
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

  Widget _buildAnnouncementsList(List<AnnouncementModel> announcements) {
    return FutureBuilder<UserModel?>(
      future: UserService.getCurrentUser(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final currentUser = userSnapshot.data;
        
        // Filter announcements based on user permissions
        List<AnnouncementModel> permissionFiltered = announcements.where((announcement) {
          if (currentUser == null) return false;
          
          // Admins can see all announcements
          if (currentUser.isAdmin) return true;
          
          // Moderators can only see announcements from their clubs
          if (currentUser.isModerator) {
            return currentUser.canModerate(announcement.clubId);
          }
          
          // Regular users can only see approved announcements from their clubs or public ones
          return currentUser.isMemberOf(announcement.clubId) || 
                 announcement.visibility == AnnouncementVisibility.public;
        }).toList();
        
        // Apply other filters
        final filteredAnnouncements = _getFilteredAnnouncements(permissionFiltered);
        
        if (filteredAnnouncements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.announcement_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No announcements found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _cachedAnnouncements = null;
            });
            await _initializeData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAnnouncements.length,
            itemBuilder: (context, index) {
              final announcement = filteredAnnouncements[index];
              return _buildAnnouncementCard(announcement);
            },
            // Add performance optimizations
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            cacheExtent: 1000,
            // Add safety checks for layout
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: false,
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);
    final isRead = _readAnnouncements.contains(announcement.id);
    final isSaved = _savedAnnouncements.contains(announcement.id);
    final timeAgo = timeago.format(announcement.createdAt, allowFromNow: true);
    final hasClubName = (announcement.clubName.isNotEmpty);
    
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _showAnnouncementDetails(announcement),
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
                      imageUrl: announcement.imageUrl ?? 'https://via.placeholder.com/400x200/1E3A8A/FFFFFF?text=Announcement+Image',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary.withOpacity(0.1), secondary.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                              SizedBox(height: 8),
                              Text('Loading...', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500)),
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
                  // Status Badge - Only show if not approved
                  if (announcement.status != AnnouncementStatus.approved)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getAnnouncementStatusColor(announcement.status).withOpacity(0.9),
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
                          announcement.statusName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Important Badge
                  if (announcement.isImportant)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.priority_high, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'IMPORTANT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Pin Badge
                  if (announcement.isPinned)
                    Positioned(
                      top: announcement.isImportant ? 50 : 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: secondary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.push_pin, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'PINNED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: GoogleFonts.poppins(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 18,
                              color: isRead ? Colors.grey[700] : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            announcement.typeName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Content preview
                    Text(
                      announcement.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Range Information
                    if (announcement.startDate != null || announcement.endDate != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (announcement.startDate != null)
                                    Text(
                                      'From: ${DateFormat('MMM dd, yyyy').format(announcement.startDate!)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  if (announcement.endDate != null)
                                    Text(
                                      'Until: ${DateFormat('MMM dd, yyyy').format(announcement.endDate!)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (announcement.startDate != null || announcement.endDate != null)
                      const SizedBox(height: 16),
                    // Announcement Details Row - Made more responsive
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        // Date & Time
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 16, color: primary),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(announcement.createdAt),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    timeAgo,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Author/Club
                        if (hasClubName)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.group, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    announcement.clubName,
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
                    // Bottom Row with Actions - Made more responsive
                    Row(
                      children: [
                        // Read Status
                        if (!isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'NEW',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        // Action Buttons - Made more compact
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Save Button
                            IconButton(
                              onPressed: () => _toggleSaved(announcement.id),
                              icon: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: isSaved ? secondary : Colors.grey[600],
                                size: 20,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Edit and Delete buttons for moderators/admins
                            FutureBuilder<UserModel?>(
                              future: UserService.getCurrentUser(),
                              builder: (context, snapshot) {
                                final user = snapshot.data;
                                if (user != null && (user.isAdmin || user.canModerate(announcement.clubId))) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _showEditAnnouncementDialog(announcement),
                                        icon: const Icon(Icons.edit, size: 20),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.blue[100],
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        onPressed: () => _showDeleteAnnouncementDialog(announcement),
                                        icon: const Icon(Icons.delete, size: 20),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red[100],
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(8),
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
                              onPressed: () => _shareAnnouncement(announcement),
                              icon: const Icon(Icons.share, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
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
      ),
    );
  }

  Color _getAnnouncementStatusColor(AnnouncementStatus status) {
    switch (status) {
      case AnnouncementStatus.approved:
        return Colors.green;
      case AnnouncementStatus.pending:
        return Colors.orange;
      case AnnouncementStatus.rejected:
        return Colors.red;
      case AnnouncementStatus.draft:
        return Colors.grey;
      case AnnouncementStatus.active:
        return Colors.blue;
      case AnnouncementStatus.archived:
        return Colors.purple;
    }
  }

  void _showAnnouncementDetails(AnnouncementModel announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header and Action buttons
            _buildDetailsHeader(context, announcement),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          announcement.clubName,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(announcement.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      announcement.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    if (announcement.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: announcement.tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                            labelStyle: const TextStyle(color: Color(0xFF3B82F6)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsHeader(BuildContext context, AnnouncementModel announcement) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              announcement.title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FutureBuilder<UserModel?>(
            future: UserService.getCurrentUser(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final user = snapshot.data!;
              final isOwner = currentUser?.uid == announcement.createdBy;
              
              if (user.isAdmin || isOwner) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                      onPressed: () {
                        _showEditAnnouncementDialog(announcement);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteAnnouncementDialog(announcement);
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _showEditAnnouncementDialog(AnnouncementModel announcement) async {
    // Check user permissions first
    final user = await UserService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to edit announcements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user can edit this announcement
    if (!user.isAdmin && !user.canModerate(announcement.clubId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit announcements from clubs you moderate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController(text: announcement.title);
    final contentController = TextEditingController(text: announcement.content);
    String selectedCategory = announcement.tags.isNotEmpty ? announcement.tags.first : 'Academic';
    String selectedPriority = announcement.isImportant ? 'Important' : 'Normal';
    String selectedVisibility = announcement.visibility == AnnouncementVisibility.public ? 'Public' : 'Club';
    bool isImportant = announcement.isImportant;
    bool isPinned = announcement.isPinned;
    String? imageUrl = announcement.imageUrl;
    bool imageUploading = false;
    DateTime? startDate = announcement.startDate;
    DateTime? endDate = announcement.endDate;
    final List<String> priorityOptions = ['Normal', 'Important', 'Urgent'];
    final List<String> visibilityOptions = ['Public', 'Department', 'Club'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced Image Upload Section
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                  ),
                  child: imageUploading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Uploading image...'),
                          ],
                        ),
                      )
                    : imageUrl != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl!,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                      onPressed: () async {
                                        await _handleImageUpload(
                                          setState, 
                                          (url) => imageUrl = url, 
                                          (state) => imageUploading = state
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                      onPressed: () => setState(() { imageUrl = null; }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _handleImageUpload(
                                setState, 
                                (url) => imageUrl = url, 
                                (state) => imageUploading = state
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Title Field
                TextField(
                  controller: titleController,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Announcement Title *',
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                // Content Field
                TextField(
                  controller: contentController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Content *',
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                // Category and Priority Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: _categories.where((cat) => cat != 'All').map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category, style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.priority_high),
                        ),
                        items: priorityOptions.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority, style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPriority = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Visibility Dropdown
                DropdownButtonFormField<String>(
                  value: selectedVisibility,
                  decoration: InputDecoration(
                    labelText: 'Visibility',
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.visibility),
                  ),
                  items: visibilityOptions.map((visibility) {
                    return DropdownMenuItem(
                      value: visibility,
                      child: Text(visibility, style: GoogleFonts.poppins()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVisibility = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Date Range Fields
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                startDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    startDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(startDate!)
                                      : 'Start Date (Optional)',
                                    style: GoogleFonts.poppins(
                                      color: startDate != null ? Colors.black87 : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? (startDate ?? DateTime.now()),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                endDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    endDate != null 
                                      ? DateFormat('MMM dd, yyyy').format(endDate!)
                                      : 'End Date (Optional)',
                                    style: GoogleFonts.poppins(
                                      color: endDate != null ? Colors.black87 : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Checkboxes for Important and Pinned
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Mark as Important', style: GoogleFonts.poppins(fontSize: 14)),
                        value: isImportant,
                        onChanged: (value) {
                          setState(() {
                            isImportant = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Pin Announcement', style: GoogleFonts.poppins(fontSize: 14)),
                        value: isPinned,
                        onChanged: (value) {
                          setState(() {
                            isPinned = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Show loading state
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Updating announcement...'),
                    ],
                  ),
                ),
              );

              try {
                // Pre-process data
                final importance = selectedPriority == 'Important' || selectedPriority == 'Urgent';

                // Update announcement data
                final announcementData = {
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                  'type': selectedCategory.toLowerCase(),
                  'updatedAt': Timestamp.now(),
                  'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
                  'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
                  'tags': [selectedCategory],
                  'visibility': selectedVisibility.toLowerCase(),
                  'isImportant': importance || isImportant,
                  'isPinned': isPinned,
                  'imageUrl': imageUrl,
                };

                await _announcementService.updateAnnouncement(announcement.id, announcementData);

                // Send notification asynchronously without waiting
                NotificationService().sendNotificationToAdmins(
                  title: 'Announcement Updated',
                  message: 'Announcement "${titleController.text}" updated by ${user.fullName}',
                  type: NotificationType.announcementUpdate,
                  priority: NotificationPriority.normal,
                  data: {'announcementId': announcement.id},
                ).catchError((error) {
                  print('Notification error: $error');
                });

                Navigator.pop(context); // Close loading dialog
                Navigator.pop(context); // Close edit dialog
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement updated successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating announcement: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Update Announcement',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAnnouncementDialog(AnnouncementModel announcement) async {
    // Check user permissions first
    final user = await UserService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to delete announcements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user can delete this announcement
    if (!user.isAdmin && !user.canModerate(announcement.clubId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete announcements from clubs you moderate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete "${announcement.title}"?'),
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
                await _announcementService.deleteAnnouncement(announcement.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Announcement "${announcement.title}" deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // Moderator needs to request deletion
                await _announcementService.requestAnnouncementDeletion(
                  announcement.id,
                  user.id,
                  reasonController.text.isEmpty ? 'No reason provided' : reasonController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deletion request sent for "${announcement.title}"'),
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
}
