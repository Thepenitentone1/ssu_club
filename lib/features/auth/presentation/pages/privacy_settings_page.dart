import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/user_service.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  late PrivacySettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      final settings = await UserService.getUserPrivacySettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await UserService.saveUserPrivacySettings(_settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  void _updateSetting(String key, bool value) {
    setState(() {
      switch (key) {
        case 'profileVisibility':
          _settings = _settings.copyWith(profileVisibility: value);
          break;
        case 'showEmail':
          _settings = _settings.copyWith(showEmail: value);
          break;
        case 'showPhoneNumber':
          _settings = _settings.copyWith(showPhoneNumber: value);
          break;
        case 'showJoinedClubs':
          _settings = _settings.copyWith(showJoinedClubs: value);
          break;
        case 'showEvents':
          _settings = _settings.copyWith(showEvents: value);
          break;
        case 'allowClubInvitations':
          _settings = _settings.copyWith(allowClubInvitations: value);
          break;
        case 'allowEventInvitations':
          _settings = _settings.copyWith(allowEventInvitations: value);
          break;
        case 'allowMessages':
          _settings = _settings.copyWith(allowMessages: value);
          break;
      }
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Control your privacy settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Profile Visibility'),
                  subtitle: const Text('Make your profile visible to other users'),
                  value: _settings.profileVisibility,
                  onChanged: (value) => _updateSetting('profileVisibility', value),
                ),
                SwitchListTile(
                  title: const Text('Show Email'),
                  subtitle: const Text('Allow others to see your email address'),
                  value: _settings.showEmail,
                  onChanged: (value) => _updateSetting('showEmail', value),
                ),
                SwitchListTile(
                  title: const Text('Show Phone Number'),
                  subtitle: const Text('Allow others to see your phone number'),
                  value: _settings.showPhoneNumber,
                  onChanged: (value) => _updateSetting('showPhoneNumber', value),
                ),
                SwitchListTile(
                  title: const Text('Show Joined Clubs'),
                  subtitle: const Text('Display your club memberships on your profile'),
                  value: _settings.showJoinedClubs,
                  onChanged: (value) => _updateSetting('showJoinedClubs', value),
                ),
                SwitchListTile(
                  title: const Text('Show Events'),
                  subtitle: const Text('Display your event participation on your profile'),
                  value: _settings.showEvents,
                  onChanged: (value) => _updateSetting('showEvents', value),
                ),
                SwitchListTile(
                  title: const Text('Allow Club Invitations'),
                  subtitle: const Text('Allow others to invite you to clubs'),
                  value: _settings.allowClubInvitations,
                  onChanged: (value) => _updateSetting('allowClubInvitations', value),
                ),
                SwitchListTile(
                  title: const Text('Allow Event Invitations'),
                  subtitle: const Text('Allow others to invite you to events'),
                  value: _settings.allowEventInvitations,
                  onChanged: (value) => _updateSetting('allowEventInvitations', value),
                ),
                SwitchListTile(
                  title: const Text('Allow Messages'),
                  subtitle: const Text('Allow others to send you messages'),
                  value: _settings.allowMessages,
                  onChanged: (value) => _updateSetting('allowMessages', value),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Blocked Users'),
                  subtitle: Text('${_settings.blockedUsers.length} users blocked'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showBlockedUsersDialog(),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Data Usage'),
                  subtitle: const Text('Manage how your data is used'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showDataUsageDialog(),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Delete Account'),
                  subtitle: const Text('Permanently delete your account and data'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showDeleteAccountDialog(),
                ),
              ],
            ),
    );
  }

  void _showBlockedUsersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blocked Users'),
        content: _settings.blockedUsers.isEmpty
            ? const Text('No users are currently blocked.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _settings.blockedUsers.map((userId) => ListTile(
                  title: Text('User $userId'),
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await UserService.unblockUser(userId);
                        Navigator.pop(context);
                        _loadSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User unblocked successfully!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error unblocking user: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Unblock'),
                  ),
                )).toList(),
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

  void _showDataUsageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Usage'),
        content: const Text(
          'Your data is used to provide you with a personalized experience, including:\n\n'
          '• Club recommendations based on your interests\n'
          '• Event suggestions based on your location and preferences\n'
          '• Personalized notifications and updates\n'
          '• Improving app functionality and user experience\n\n'
          'We do not sell your personal data to third parties.',
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently remove:\n\n'
          '• Your profile and personal information\n'
          '• Your club memberships and applications\n'
          '• Your event participations and RSVPs\n'
          '• All your messages and notifications\n\n'
          'This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await UserService.deleteUserAccount();
                Navigator.pop(context);
                // Navigate to login page or show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deleted successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 