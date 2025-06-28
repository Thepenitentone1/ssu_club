import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();
  UserNotificationSettings _settings = UserNotificationSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      final settings = await _notificationService.getUserNotificationSettings();
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
      await _notificationService.saveUserNotificationSettings(_settings);
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
        case 'clubAnnouncements':
          _settings = _settings.copyWith(clubAnnouncements: value);
          break;
        case 'eventReminders':
          _settings = _settings.copyWith(eventReminders: value);
          break;
        case 'newMessages':
          _settings = _settings.copyWith(newMessages: value);
          break;
        case 'clubInvitations':
          _settings = _settings.copyWith(clubInvitations: value);
          break;
        case 'eventUpdates':
          _settings = _settings.copyWith(eventUpdates: value);
          break;
        case 'newsAndUpdates':
          _settings = _settings.copyWith(newsAndUpdates: value);
          break;
        case 'emailNotifications':
          _settings = _settings.copyWith(emailNotifications: value);
          break;
        case 'pushNotifications':
          _settings = _settings.copyWith(pushNotifications: value);
          break;
        case 'vibration':
          _settings = _settings.copyWith(vibration: value);
          break;
      }
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  value: _settings.pushNotifications,
                  onChanged: (value) => _updateSetting('pushNotifications', value),
                ),
                SwitchListTile(
                  title: const Text('Club Announcements'),
                  value: _settings.clubAnnouncements,
                  onChanged: (value) => _updateSetting('clubAnnouncements', value),
                ),
                SwitchListTile(
                  title: const Text('Event Reminders'),
                  value: _settings.eventReminders,
                  onChanged: (value) => _updateSetting('eventReminders', value),
                ),
                SwitchListTile(
                  title: const Text('New Messages'),
                  value: _settings.newMessages,
                  onChanged: (value) => _updateSetting('newMessages', value),
                ),
                SwitchListTile(
                  title: const Text('Club Invitations'),
                  value: _settings.clubInvitations,
                  onChanged: (value) => _updateSetting('clubInvitations', value),
                ),
                SwitchListTile(
                  title: const Text('Event Updates'),
                  value: _settings.eventUpdates,
                  onChanged: (value) => _updateSetting('eventUpdates', value),
                ),
                SwitchListTile(
                  title: const Text('News and Updates'),
                  value: _settings.newsAndUpdates,
                  onChanged: (value) => _updateSetting('newsAndUpdates', value),
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  value: _settings.emailNotifications,
                  onChanged: (value) => _updateSetting('emailNotifications', value),
                ),
                SwitchListTile(
                  title: const Text('Vibration'),
                  value: _settings.vibration,
                  onChanged: (value) => _updateSetting('vibration', value),
                ),
              ],
            ),
    );
  }
} 