import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'config/firebase_init.dart';
import 'features/clubs/presentation/pages/clubs_page.dart';
import 'features/events/presentation/pages/events_page.dart';
import 'features/announcements/presentation/pages/announcements_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/profile_setup_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'features/auth/presentation/pages/sign_in_page.dart' as log_in;
import 'features/auth/presentation/pages/sign_up_page.dart';
import 'features/auth/presentation/pages/app_intro_page.dart';
import 'features/auth/presentation/pages/thank_you_page.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/chat/presentation/pages/conversations_page.dart';
import 'core/services/cloudinary_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/user_service.dart';
import 'shared/widgets/loading_widget.dart';
import 'shared/widgets/notification_badge.dart';
import 'core/theme/theme_provider.dart';
import 'features/main/presentation/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }
  await FirebaseInit.initialize();
  
  // Initialize Cloudinary
  CloudinaryStorageService.initialize();
  
  // Initialize notifications (only on mobile)
  if (!kIsWeb) {
    await NotificationService.initialize();
  }
  
  runApp(
    provider.ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'SSU Club Hub',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthGate(),
            '/log-in': (context) => const log_in.LogInPage(),
            '/sign-up': (context) => const SignUpPage(),
            '/intro': (context) => const AppIntroPage(),
            '/thank-you': (context) => const ThankYouPage(),
            '/profile-setup': (context) => const ProfileSetupPage(),
            '/main': (context) => const HomePage(),
          },
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FullScreenLoading(message: 'Checking authentication...');
        }
        if (snapshot.hasData) {
          return const ProfileCheckGate();
        } else {
          return const AppIntroPage();
        }
      },
    );
  }
}

class ProfileCheckGate extends StatelessWidget {
  const ProfileCheckGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: UserService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FullScreenLoading(message: 'Loading profile...');
        }
        
        if (snapshot.hasError) {
          return const HomePage(); // Fallback to home page if error
        }
        
        final user = snapshot.data;
        if (user == null) {
          // New user - show profile setup
          return const ProfileSetupPage();
        }
        
        // Existing user - check if profile is complete
        if (!user.isProfileComplete) {
          return const ProfileSetupPage();
        }
        
        // User has complete profile - go to home page
        return const HomePage();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  final List<Widget> _pages = [
    const MainPage(),
    const ClubsPage(),
    const EventsPage(),
    const AnnouncementsPage(),
    const ConversationsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const FullScreenLoading(message: 'Loading SSU Club Hub...');
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E3A8A).withOpacity(0.05),
                const Color(0xFF3B82F6).withOpacity(0.05),
                Colors.white.withOpacity(0.9),
              ],
            ),
          ),
          child: _selectedIndex < _pages.length ? _pages[_selectedIndex] : _pages[0],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.group_outlined, Icons.group, 'Clubs'),
                _buildNavItem(2, Icons.event_outlined, Icons.event, 'Events'),
                _buildNavItem(3, Icons.announcement_outlined, Icons.announcement, 'News'),
                _buildNavItem(4, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
                _buildNavItem(5, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);
    
    Widget navItem = GestureDetector(
      onTap: () {
        // Add haptic feedback
        HapticFeedback.lightImpact();
        
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? secondary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(
            color: secondary.withOpacity(0.3),
            width: 1.5,
          ) : null,
          boxShadow: isSelected ? [
            BoxShadow(
              color: secondary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // Add notification badge for profile tab
                if (index == 5) // Profile tab
                  NotificationBadge(
                    size: 16,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? selectedIcon : icon,
                        color: isSelected ? secondary : Colors.grey[600],
                        size: isSelected ? 26 : 24,
                      ),
                    ),
                  )
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      color: isSelected ? secondary : Colors.grey[600],
                      size: isSelected ? 26 : 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.poppins(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? secondary : Colors.grey[600],
              ),
              child: Text(label),
            ),
            // Animated indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 4),
              height: isSelected ? 3 : 0,
              width: isSelected ? 20 : 0,
              decoration: BoxDecoration(
                color: secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );

    // Add simple scale animation for selected items
    if (isSelected) {
      return navItem.animate().scale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.0, 1.0),
      );
    }

    return navItem.animate().scale(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.0, 1.0),
    );
  }

  Stream<int> _getUnreadNotificationCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);
    
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUserId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRefreshing = false);
  }

  void _navigateToPage(int index) {
    final _HomePageState? homeState = context.findAncestorStateOfType<_HomePageState>();
    if (homeState != null) {
      homeState.setState(() {
        homeState._selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner with animation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Hero(
                          tag: 'ssu_logo',
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.school, size: 48, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to SSU Club Hub',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Your student life companion',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),
              const SizedBox(height: 16),

              // Quick Actions with animations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.8,
                      children: [
                        _buildQuickActionCard(
                          context,
                          'Clubs',
                          Icons.group,
                          const Color(0xFF3B82F6),
                          () => _navigateToPage(1),
                        ),
                        _buildQuickActionCard(
                          context,
                          'Events',
                          Icons.event,
                          const Color(0xFF2563EB),
                          () => _navigateToPage(2),
                        ),
                        _buildQuickActionCard(
                          context,
                          'News',
                          Icons.announcement,
                          const Color(0xFF1D4ED8),
                          () => _navigateToPage(3),
                        ),
                        _buildQuickActionCard(
                          context,
                          'Profile',
                          Icons.person,
                          const Color(0xFF1E3A8A),
                          () => _navigateToPage(5),
                        ),
                        _buildQuickActionCard(
                          context,
                          'Chat',
                          Icons.chat_bubble_outline,
                          const Color(0xFF3730A3),
                          () => _navigateToPage(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: 0.2, end: 0),
              const SizedBox(height: 16),

              // Upcoming Events with animations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Events',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () => _navigateToPage(2),
                          icon: Icon(
                            Icons.event,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: const Text('All Events'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildEventCard(
                            context,
                            'SSU Foundation Day',
                            'June 21',
                            'Main Campus',
                            Icons.celebration,
                            Colors.blue,
                          ),
                          _buildEventCard(
                            context,
                            'Research Symposium',
                            'May 15',
                            'Conference Hall',
                            Icons.science,
                            Colors.green,
                          ),
                          _buildEventCard(
                            context,
                            'Cultural Festival',
                            'April 20',
                            'Gymnasium',
                            Icons.theater_comedy,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: -0.2, end: 0),
              const SizedBox(height: 16),

              // Latest News with animations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Latest News',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: () => _navigateToPage(3),
                          icon: Icon(
                            Icons.announcement,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: const Text('All News'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildAnnouncementCard(
                      context,
                      'Enrollment Schedule AY 2024-2025',
                      'Office of the Registrar',
                      '2 days ago',
                      Icons.school,
                      Colors.blue,
                    ),
                    _buildAnnouncementCard(
                      context,
                      'Research Grant Applications Open',
                      'Research Office',
                      '3 days ago',
                      Icons.science,
                      Colors.green,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData iconData,
    Color color,
    VoidCallback onTap,
  ) {
    return Hero(
      tag: 'action_$title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(delay: const Duration(milliseconds: 200));
  }

  Widget _buildEventCard(
    BuildContext context,
    String title,
    String date,
    String location,
    IconData iconData,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToPage(2),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                iconData,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    String title,
    String author,
    String time,
    IconData iconData,
    Color color,
  ) {
    return Hero(
      tag: 'announcement_$title',
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToPage(3),
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                size: 24,
                color: color,
              ),
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: Text(
              '$author • $time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: color.withOpacity(0.5),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
