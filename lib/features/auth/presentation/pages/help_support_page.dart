import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isExpanded = false;

  final List<Map<String, dynamic>> faqs = [
    {
      'question': 'How do I join a club?',
      'answer':
          'To join a club, navigate to the Clubs page, find the club you\'re interested in, and click the "Join" button. You may need to wait for approval from the club administrators.',
      'category': 'Clubs',
    },
    {
      'question': 'How do I create a new club?',
      'answer':
          'To create a new club, go to the Clubs page and click the "+" button. Fill out the required information and submit for approval from the student council.',
      'category': 'Clubs',
    },
    {
      'question': 'How do I manage my notifications?',
      'answer':
          'You can manage your notifications in the Profile page under Settings > Notification Settings. Here you can customize which notifications you want to receive.',
      'category': 'Notifications',
    },
    {
      'question': 'How do I update my profile?',
      'answer':
          'To update your profile, go to the Profile page and click on "Edit Profile". Here you can update your information, profile picture, and other details.',
      'category': 'Profile',
    },
    {
      'question': 'How do I report an issue?',
      'answer':
          'You can report issues by contacting support through the "Contact Support" option in this page, or by emailing support@ssuclubhub.edu.ph.',
      'category': 'Support',
    },
    {
      'question': 'How do I RSVP to events?',
      'answer':
          'To RSVP to an event, go to the Events page, find the event you want to attend, and click the "RSVP" button. You can also manage your RSVPs from your profile.',
      'category': 'Events',
    },
    {
      'question': 'How do I change my privacy settings?',
      'answer':
          'Go to your Profile page and select "Privacy" from the settings. Here you can control what information is visible to other users.',
      'category': 'Privacy',
    },
    {
      'question': 'How do I block a user?',
      'answer':
          'To block a user, go to Privacy Settings and select "Blocked Users". You can add users to your blocked list from there.',
      'category': 'Privacy',
    },
  ];

  List<Map<String, dynamic>> get filteredFaqs {
    if (_searchQuery.isEmpty) return faqs;
    return faqs.where((faq) {
      return faq['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             faq['category'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.08),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search Bar
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for help...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            'Contact Support',
                            Icons.support_agent,
                            () => _showContactSupportDialog(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickActionCard(
                            context,
                            'Report Bug',
                            Icons.bug_report,
                            () => _showReportBugDialog(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FAQs
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.question_answer,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Frequently Asked Questions',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredFaqs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try searching with different keywords',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredFaqs.map((faq) => _buildFAQItem(context, faq)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact Information
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contact_support,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Contact Information',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(
                      context,
                      'Email',
                      'support@ssuclubhub.edu.ph',
                      Icons.email,
                      () async {
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'support@ssuclubhub.edu.ph',
                          query: 'subject=SSU Club Hub Support Request',
                        );
                        if (await canLaunchUrl(emailLaunchUri)) {
                          await launchUrl(emailLaunchUri);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildContactItem(
                      context,
                      'Phone',
                      '+63 123 456 7890',
                      Icons.phone,
                      () async {
                        final Uri phoneLaunchUri = Uri(
                          scheme: 'tel',
                          path: '+631234567890',
                        );
                        if (await canLaunchUrl(phoneLaunchUri)) {
                          await launchUrl(phoneLaunchUri);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildContactItem(
                      context,
                      'Office Hours',
                      'Monday - Friday, 8:00 AM - 5:00 PM',
                      Icons.access_time,
                      null,
                    ),
                    const SizedBox(height: 8),
                    _buildContactItem(
                      context,
                      'Location',
                      'Student Center, Room 101',
                      Icons.location_on,
                      null,
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

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, Map<String, dynamic> faq) {
    return ExpansionTile(
      title: Text(
        faq['question'],
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        faq['category'],
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            faq['answer'],
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text(value, style: GoogleFonts.poppins(fontSize: 14)),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }

  void _showContactSupportDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Support', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
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
              final subject = subjectController.text.trim();
              final message = messageController.text.trim();
              
              if (subject.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'support@ssuclubhub.edu.ph',
                query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}',
              );
              
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog() {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController stepsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Bug', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Bug Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stepsController,
              decoration: const InputDecoration(
                labelText: 'Steps to Reproduce',
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
              final description = descriptionController.text.trim();
              final steps = stepsController.text.trim();
              
              if (description.isEmpty || steps.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              final message = '''
Bug Report:

Description:
$description

Steps to Reproduce:
$steps

Device: ${Theme.of(context).platform}
App Version: 1.0.0
              ''';

              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'support@ssuclubhub.edu.ph',
                query: 'subject=${Uri.encodeComponent('Bug Report - SSU Club Hub')}&body=${Uri.encodeComponent(message)}',
              );
              
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
} 