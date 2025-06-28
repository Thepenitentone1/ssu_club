import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../events/data/services/event_service.dart';
import '../../../announcements/data/services/announcement_service.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/models/announcement.dart';
import '../../../../core/services/user_service.dart';
import '../../../auth/presentation/pages/notification_settings_page.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDarkMode = ref.watch(themeProvider).isDarkMode;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textPrimary = isDarkMode ? Colors.white : Colors.black;
    final Color textSecondary = isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final Color accent = const Color(0xFF2563EB);
    final Color sectionBg = isDarkMode ? Colors.grey[850]! : const Color(0xFFF8FAFC);

    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    int getSelectedIndex() {
      if (currentRoute.startsWith('/clubs')) {
        return 1;
      } else if (currentRoute.startsWith('/events')) {
        return 2;
      } else if (currentRoute.startsWith('/announcements')) {
        return 3;
      } else if (currentRoute.startsWith('/profile')) {
        return 4;
      } else {
        return 0;
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'SSU Club Hub',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage(),
                  ),
                );
              },
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.go('/profile');
              },
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: _FirestoreHomeContent(),
        ),
      ),
    );
  }
}

class _FirestoreHomeContent extends StatelessWidget {
  const _FirestoreHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF6B8AFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to SSU Club Hub',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Your student life companion',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickActionCard(icon: Icons.school, label: 'Clubs', color: Colors.blue[100]!),
                _QuickActionCard(icon: Icons.event, label: 'Events', color: Colors.green[100]!),
                _QuickActionCard(icon: Icons.announcement, label: 'News', color: Colors.orange[100]!),
                _QuickActionCard(icon: Icons.person, label: 'Profile', color: Colors.purple[100]!),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Upcoming Events Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming Events', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(
                  onPressed: () {},
                  child: Text('All Events', style: GoogleFonts.poppins(color: accent)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: StreamBuilder<List<EventModel>>(
              stream: EventService().getEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = (snapshot.data ?? []).where((e) => e.status == EventStatus.approved).toList();
                if (events.isEmpty) {
                  return Center(child: Text('No upcoming events.', style: GoogleFonts.poppins()));
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length > 5 ? 5 : events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final e = events[i];
                    return Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Placeholder for image/avatar
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.event, color: accent, size: 28),
                                ),
                                const SizedBox(height: 12),
                                Text(e.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(DateFormat('MMM d').format(e.startDate), style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13)),
                                const SizedBox(height: 6),
                                Text(e.location ?? "TBA", style: GoogleFonts.poppins(color: accent, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          // Latest News Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Latest News', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(
                  onPressed: () {},
                  child: Text('All News', style: GoogleFonts.poppins(color: accent)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<AnnouncementModel>>(
              stream: AnnouncementService().getAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final announcements = snapshot.data ?? [];
                if (announcements.isEmpty) {
                  return Center(child: Text('No news yet.', style: GoogleFonts.poppins()));
                }
                return Column(
                  children: announcements.take(2).map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.announcement, color: Colors.orange[800]),
                      ),
                      title: Text(a.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(a.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins()),
                      onTap: () {},
                    ),
                  )).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Recent Announcements Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Announcements', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(
                  onPressed: () {},
                  child: Text('All Announcements', style: GoogleFonts.poppins(color: accent)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<AnnouncementModel>>(
              stream: AnnouncementService().getAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final announcements = (snapshot.data ?? []).where((a) => a.status == AnnouncementStatus.approved).toList();
                if (announcements.isEmpty) {
                  return Center(child: Text('No recent announcements.', style: GoogleFonts.poppins()));
                }
                return Column(
                  children: announcements.take(3).map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: (a.imageUrl != null && a.imageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(a.imageUrl!, width: 36, height: 36, fit: BoxFit.cover),
                            )
                          : Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.announcement, color: Colors.orange[800]),
                            ),
                      title: Text(a.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(a.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins()),
                      onTap: () {},
                    ),
                  )).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickActionCard({required this.icon, required this.label, required this.color});

  void _handleTap(BuildContext context) {
    switch (label) {
      case 'Clubs':
        context.go('/clubs');
        break;
      case 'Events':
        context.go('/events');
        break;
      case 'News':
        context.go('/announcements');
        break;
      case 'Profile':
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleTap(context),
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black54, size: 28),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
} 
