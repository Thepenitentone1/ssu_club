import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ssu_club_hub/features/chat/presentation/pages/chat_page.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/widgets/loading_widget.dart';

class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});

  @override
  _UserSelectionPageState createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  Future<List<UserModel>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = UserService.getAllUsersForChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Message', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(user.initials)
                      : null,
                ),
                title: Text(user.fullName),
                subtitle: Text(user.email),
                onTap: () async {
                  try {
                    final chatRoom = await ChatService.getOrCreateDirectChat(user.id);
                    Navigator.pop(context); // Pop the user selection page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(chatRoomId: chatRoom.id),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error starting chat: $e')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
} 