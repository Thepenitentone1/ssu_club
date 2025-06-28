import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/cloudinary_storage_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_settings_page.dart';
import 'privacy_settings_page.dart';
import 'help_support_page.dart';
import 'edit_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/models/user.dart';
import '../../../../core/services/user_service.dart';
import '../../../admin/presentation/pages/admin_panel_page.dart' as admin_pages;
import '../../../admin/presentation/pages/moderator_panel_page.dart';
import 'notifications_page.dart';
import '../../../../shared/models/club.dart';
import '../../../clubs/presentation/pages/clubs_page.dart';
import '../../../clubs/presentation/pages/my_clubs_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _profileImageUrl;
  bool _isUploading = false;
  final bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadCurrentUser();
  }

  Future<void> _loadProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && doc.data()?['profileImageUrl'] != null) {
          setState(() {
            _profileImageUrl = doc.data()!['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    setState(() => _isUploading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upload images')),
        );
        return;
      }

      print('🔄 Starting profile image upload...');
      final downloadUrl = await CloudinaryStorageService.uploadImageFromGallery('profiles');
      
      if (downloadUrl != null) {
        print('✅ Upload successful, saving to Firestore...');
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'profileImageUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully!'),
            backgroundColor: Color(0xFF3B82F6),
          ),
        );
      } else {
        print('❌ Upload failed - no URL returned');
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Web upload not supported. Please use mobile app for uploading images.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Test upload function
  Future<void> _testUpload() async {
    try {
      print('🧪 Testing upload functionality...');
      
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web upload testing is limited. Please use mobile app for full functionality.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Simple upload test
      final result = await CloudinaryStorageService.uploadImageFromGallery('test');
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload test successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload test failed. Check console for details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Test upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fix admin user function
  Future<void> _fixAdminUser() async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      const adminEmail = 'edward@gmail.com';
      const adminPassword = 'admin123';

      // Sign out current user if any
      await auth.signOut();

      try {
        // Try to sign in
        await auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);
        print('Signed in as $adminEmail');
      } catch (e) {
        print('Creating admin user...');
        // Create user if doesn't exist
        await auth.createUserWithEmailAndPassword(email: adminEmail, password: adminPassword);
        print('Created admin user $adminEmail');
      }

      final user = auth.currentUser;
      if (user == null) {
        throw Exception('Failed to get user');
      }

      // Update Firestore document with admin role
      await firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'email': adminEmail,
        'firstName': 'Edward',
        'lastName': 'Admin',
        'role': 'admin',
        'clubMemberships': [],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'department': 'cas',
        'campus': 'main',
        'isActive': true,
        'isProfileComplete': true,
        'visibility': 'public',
        'status': 'pending',
      }, SetOptions(merge: true));

      // Reload current user
      await _loadCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Admin user fixed! Email: edward@gmail.com, Password: admin123'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error fixing admin user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing admin user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final List<Map<String, dynamic>> _settings = [
    // Admin Panel (only for admins)
    {
      'title': 'Admin Panel',
      'icon': Icons.admin_panel_settings,
      'color': const Color(0xFFDC2626), // Red
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const admin_pages.AdminPanelPage(),
          ),
        );
      },
      'showForRoles': [UserRole.admin],
    },
    // Notifications (for all users)
    {
      'title': 'Notifications',
      'icon': Icons.notifications,
      'color': const Color(0xFF2563EB), // Medium Blue
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsPage(),
          ),
        );
      },
      'showForRoles': [UserRole.user, UserRole.moderator, UserRole.admin],
    },
    // Notification Settings (for all users)
    {
      'title': 'Notification Settings',
      'icon': Icons.notifications_active,
      'color': const Color(0xFF059669), // Green
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationSettingsPage(),
          ),
        );
      },
      'showForRoles': [UserRole.user, UserRole.moderator, UserRole.admin],
    },
    // My Clubs (for all users)
    {
      'title': 'My Clubs',
      'icon': Icons.group,
      'color': const Color(0xFF3B82F6), // Blue
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyClubsPage(),
          ),
        );
      },
      'showForRoles': [UserRole.user, UserRole.moderator, UserRole.admin],
    },
    // Edit Profile (for all users)
    {
      'title': 'Edit Profile',
      'icon': Icons.edit,
      'color': const Color(0xFF3B82F6), // Blue
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfilePage(),
          ),
        );
      },
      'showForRoles': [UserRole.user, UserRole.moderator, UserRole.admin],
    },
    // Privacy (for all users)
    {
      'title': 'Privacy',
      'icon': Icons.privacy_tip,
      'color': const Color(0xFF1D4ED8), // Deep Blue
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacySettingsPage(),
          ),
        );
      },
      'showForRoles': [UserRole.user, UserRole.moderator, UserRole.admin],
    },
    // Help & Support (for all users)
    {
      'title': 'Help & Support',
      'icon': Icons.help,
      'color': const Color(0xFF1E3A8A), // Navy Blue
      'onTap': (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HelpSupportPage(),
          ),
        );
      },
      'showForRoles': [UserRole.user, UserRole.moderator, UserRole.admin],
    },
  ];

  List<Map<String, dynamic>> _getFilteredSettings() {
    if (_currentUser == null) {
      return _settings.where((setting) => 
        setting['showForRoles']?.contains(UserRole.user) == true
      ).toList();
    }
    
    return _settings.where((setting) => 
      setting['showForRoles']?.contains(_currentUser!.role) == true
    ).toList();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFDC2626); // Red
      case UserRole.moderator:
        return const Color(0xFFEA580C); // Orange
      case UserRole.user:
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.user:
        return 'Student';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider.Provider.of<ThemeProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDarkMode = themeProvider.isDarkMode;
    final secondary = const Color(0xFF3B82F6); // Bright Blue
    final background = const Color(0xFFF8FAFC); // Light Gray Background
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, size: 22),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(0.05),
              secondary.withOpacity(0.08),
              background,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true, // This makes the header stay when scrolling
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                centerTitle: false,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primary, secondary],
                    ),
                  ),
                ),
              ),
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: secondary.withOpacity(0.1),
                                backgroundImage: _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                                child: _profileImageUrl == null
                                    ? Icon(Icons.person, size: 60, color: primary)
                                    : null,
                              ),
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: SmallLoadingWidget(
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: _isUploading ? null : _uploadProfileImage,
                                    icon: const Icon(Icons.camera_alt, size: 20),
                                    color: Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentUser?.fullName ?? 'Loading...',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          if (_currentUser != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(_currentUser!.role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRoleColor(_currentUser!.role),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getRoleDisplayName(_currentUser!.role),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getRoleColor(_currentUser!.role),
                                ),
                              ),
                            ),
                          ],
                          Text(
                            _currentUser?.email ?? 'No email available',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          // Theme Toggle
                          OutlinedButton.icon(
                            onPressed: () {
                              themeProvider.toggleTheme();
                            },
                            icon: Icon(
                              isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              color: primary,
                            ),
                            label: Text(
                              isDarkMode ? 'Light Mode' : 'Dark Mode',
                              style: TextStyle(color: primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Test Upload Button
                          OutlinedButton.icon(
                            onPressed: _testUpload,
                            icon: const Icon(Icons.upload, color: Colors.orange),
                            label: const Text(
                              'Test Upload',
                              style: TextStyle(color: Colors.orange),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Fix Admin User Button (temporary)
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Fix Admin User'),
                                    content: const Text(
                                      'This will create/update edward@gmail.com as admin with password "admin123". Continue?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFDC2626),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Fix Admin'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  // Import and call the fix function
                                  await _fixAdminUser();
                                }
                              } catch (e) {
                                print('Error fixing admin user: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error fixing admin user: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFDC2626)),
                            label: const Text(
                              'Fix Admin User',
                              style: TextStyle(color: Color(0xFFDC2626)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDC2626)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Settings
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ..._getFilteredSettings()
                      .where((setting) => setting['title'] != 'Notifications')
                      .map((setting) => _buildSettingItem(context, setting)),
                    const SizedBox(height: 24),

                    // Joined Clubs
                    if (_currentUser != null && _currentUser!.clubMemberships.isNotEmpty) ...[
                      Text(
                        'My Clubs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<ClubModel>>(
                        future: UserService.getClubsByIds(_currentUser!.clubMemberships.map((m) => m.clubId).toList()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('No clubs found.');
                          }
                          final clubs = snapshot.data!;
                          return Column(
                            children: clubs.map((club) {
                              ClubMembership? membership;
                              for (final m in _currentUser!.clubMemberships) {
                                if (m.clubId == club.id) {
                                  membership = m;
                                  break;
                                }
                              }
                              return _buildClubItem(context, {
                                'name': club.name ?? 'Unknown',
                                'role': membership != null ? membership.role.toString().split('.').last : '-',
                                'joinedDate': membership != null ? 'Joined ${membership.joinedAt.month}/${membership.joinedAt.year}' : '',
                                'color': const Color(0xFF3B82F6),
                                'logoUrl': club.logoUrl ?? '',
                              });
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            // Show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text('Are you sure you want to logout?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              // Clear any cached user data
                              setState(() {
                                _currentUser = null;
                                _profileImageUrl = null;
                              });
                              
                              // Sign out from Firebase
                              await FirebaseAuth.instance.signOut();
                              
                              // Force clear any remaining cached data
                              await Future.delayed(const Duration(milliseconds: 500));
                              
                              if (mounted) {
                                // Navigate to intro page and clear all routes
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/intro',
                                  (route) => false,
                                );
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Successfully logged out'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            print('Error during logout: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error during logout: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.logout, color: Colors.red),
                        label: Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    // Force Logout Button (for stubborn sessions)
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            // Show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Force Logout'),
                                content: const Text(
                                  'This will force a complete logout and restart the app. Use this if normal logout doesn\'t work.'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Force Logout'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              // Clear all cached data
                              setState(() {
                                _currentUser = null;
                                _profileImageUrl = null;
                              });
                              
                              // Sign out from Firebase
                              await FirebaseAuth.instance.signOut();
                              
                              // Force a longer delay to ensure everything is cleared
                              await Future.delayed(const Duration(seconds: 1));
                              
                              if (mounted) {
                                // Force restart by navigating to intro and clearing all routes
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/intro',
                                  (route) => false,
                                );
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Force logout completed. Please restart the app if needed.'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            print('Error during force logout: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error during force logout: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.refresh, color: Colors.orange),
                        label: Text(
                          'Force Logout',
                          style: TextStyle(color: Colors.orange),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, Map<String, dynamic> setting) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: setting['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            setting['icon'],
            size: 24,
            color: setting['color'],
          ),
        ),
        title: Text(
          setting['title'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: setting['color'],
        ),
        onTap: () => setting['onTap'](context),
      ),
    );
  }

  Widget _buildClubItem(BuildContext context, Map<String, dynamic> club) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            club['logoUrl'],
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 48,
              height: 48,
              color: club['color'].withOpacity(0.1),
              child: Icon(Icons.group, size: 32, color: club['color']),
            ),
          ),
        ),
        title: Text(
          club['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              club['role'],
              style: TextStyle(color: club['color'], fontWeight: FontWeight.w500),
            ),
            Text(
              'Joined ${club['joinedDate']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: club['color'],
        ),
        onTap: () {
          // TODO: Show club details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing ${club['name']} details...'),
              backgroundColor: club['color'],
            ),
          );
        },
      ),
    );
  }
} 