import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';

import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/models/chat.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/cloudinary_storage_service.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  const ChatPage({super.key, required this.chatRoomId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _messagesSubscription;
  UserModel? _currentUser;
  ChatRoom? _chatRoom;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _showEmojiPicker = false;
  bool _isEditing = false;
  String? _editingMessageId;
  String? _replyToId;
  String? _replyToContent;
  bool _isTyping = false;
  late AnimationController _typingController;
  late AnimationController _sendButtonController;
  String? _pendingImageUrl;
  final Set<String> _pinnedMessageIds = {};
  final Set<String> _unreadMessageIds = {};
  bool _isMuted = false;

  // Modern color scheme
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryBlue = Color(0xFF1E40AF);
  static const Color lightBlue = Color(0xFFDBEAFE);
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadInitialData();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _typingController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() => _isTyping = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final user = await UserService.getCurrentUser();
    final chatRoom = await ChatService.getChatRoom(widget.chatRoomId);

    if (mounted) {
      setState(() {
        _currentUser = user;
        _chatRoom = chatRoom;
      });

      _messagesSubscription = ChatService.getMessages(widget.chatRoomId).listen((messages) {
        if (mounted) {
          setState(() => _messages = messages);
          _scrollToBottom();
        }
      });
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_chatRoom == null) return;
    final content = _messageController.text.trim();
    if (content.isEmpty && _pendingImageUrl == null) return;
    _messageController.clear();
    setState(() => _showEmojiPicker = false);

    try {
      if (_isEditing && _editingMessageId != null) {
        await ChatService.editMessage(
          chatRoomId: _chatRoom!.id,
          messageId: _editingMessageId!,
          newContent: content,
        );
        setState(() {
          _isEditing = false;
          _editingMessageId = null;
        });
      } else if (_pendingImageUrl != null) {
        await ChatService.sendMessage(
          chatRoomId: _chatRoom!.id,
          content: content.isEmpty ? '[image]' : content,
          type: MessageType.image,
          imageUrl: _pendingImageUrl,
          replyToMessageId: _replyToId,
          replyToMessageContent: _replyToContent,
        );
        setState(() {
          _pendingImageUrl = null;
          _replyToId = null;
          _replyToContent = null;
        });
      } else {
        await ChatService.sendMessage(
          chatRoomId: _chatRoom!.id,
          content: content,
          replyToMessageId: _replyToId,
          replyToMessageContent: _replyToContent,
        );
        setState(() {
          _replyToId = null;
          _replyToContent = null;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Send Image'),
                onTap: () async {
                  Navigator.pop(context);
                  final imageUrl = await CloudinaryStorageService.uploadImageFromGallery('chat_images');
                  if (imageUrl != null) {
                    setState(() {
                      _pendingImageUrl = imageUrl;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.green),
                title: const Text('Send File'),
                onTap: () async {
                  Navigator.pop(context);
                  final fileUrl = await CloudinaryStorageService.pickAndUploadFile('chat_files');
                  if (fileUrl != null) {
                    final fileName = fileUrl.split('/').last;
                    await ChatService.sendMessage(
                      chatRoomId: _chatRoom!.id,
                      content: '[file] $fileName',
                      type: MessageType.file,
                      fileUrl: fileUrl,
                      fileName: fileName,
                      replyToMessageId: _replyToId,
                      replyToMessageContent: _replyToContent,
                    );
                    setState(() {
                      _replyToId = null;
                      _replyToContent = null;
                    });
                    _scrollToBottom();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onEmojiSelected(String emoji) {
    _messageController.text += emoji;
    setState(() {});
  }

  void _onReply(ChatMessage message) {
    setState(() {
      _replyToId = message.id;
      _replyToContent = message.content;
    });
  }

  void _onEdit(ChatMessage message) {
    setState(() {
      _isEditing = true;
      _editingMessageId = message.id;
      _messageController.text = message.content;
    });
  }

  void _onCancelEdit() {
    setState(() {
      _isEditing = false;
      _editingMessageId = null;
      _messageController.clear();
    });
  }

  void _onCancelReply() {
    setState(() {
      _replyToId = null;
      _replyToContent = null;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: _buildModernAppBar(),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _chatRoom == null
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Reply/Edit indicators
                    if (_replyToId != null && _replyToContent != null)
                      _buildReplyIndicator(),
                    if (_isEditing)
                      _buildEditIndicator(),
                    
                    // Messages list
                    Expanded(
                      child: _messages.isEmpty
                          ? _buildEmptyChatState()
                          : _buildMessagesList(),
                    ),
                    
                    // Input field
                    _buildModernInputField(),
                    
                    // Emoji picker
                    if (_showEmojiPicker)
                      _buildEmojiPicker(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chat not found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The chat you\'re looking for doesn\'t exist',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send your first message to begin chatting',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.reply,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to message',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToContent!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: textSecondary),
            onPressed: _onCancelReply,
            iconSize: 20,
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildEditIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: warningOrange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Editing message...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: warningOrange,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: textSecondary),
            onPressed: _onCancelEdit,
            iconSize: 20,
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == _currentUser?.id;
        return _buildModernMessageBubble(msg, isMe);
      },
    );
  }

  Widget _buildModernMessageBubble(ChatMessage message, bool isMe) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final margin = isMe 
        ? const EdgeInsets.only(left: 40, top: 12, bottom: 12, right: 8)
        : const EdgeInsets.only(right: 40, top: 12, bottom: 12, left: 8);
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: Radius.circular(isMe ? 24 : 8),
      bottomRight: Radius.circular(isMe ? 8 : 24),
    );
    final isPinned = _pinnedMessageIds.contains(message.id);
    final isUnread = _unreadMessageIds.contains(message.id);
    final statusText = message.readBy.length > 1
        ? 'Seen'
        : message.readBy.isNotEmpty
            ? 'Delivered'
            : 'Sent';
    final statusIcon = message.readBy.length > 1
        ? Icons.done_all
        : message.readBy.isNotEmpty
            ? Icons.done_all
            : Icons.check;
    final statusColor = message.readBy.length > 1
        ? successGreen
        : message.readBy.isNotEmpty
            ? Colors.grey[400]
            : Colors.grey[400];
    String fullTimestamp = _formatTimestamp(message.timestamp);
    String shortTime = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    Widget messageContent;
    if (message.type == MessageType.image && message.imageUrl != null) {
      messageContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: message.imageUrl!,
          width: 260,
          height: 260,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 260,
            height: 260,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 260,
            height: 260,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      );
    } else if (message.type == MessageType.file && message.fileUrl != null) {
      messageContent = GestureDetector(
        onTap: () async {
          final url = message.fileUrl!;
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.blue, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.fileName ?? 'File',
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.white : textPrimary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.download, size: 18, color: Colors.blue),
          ],
        ),
      );
    } else {
      messageContent = Text(
        message.content,
        style: GoogleFonts.poppins(
          color: isMe ? Colors.white : textPrimary,
          fontSize: 17,
          height: 1.5,
        ),
      );
    }

    // State for showing the menu
    final ValueNotifier<bool> showMenu = ValueNotifier(false);
    final ValueNotifier<bool> showFullTime = ValueNotifier(false);
    final ValueNotifier<List<UserModel>> seenUsers = ValueNotifier([]);
    final ValueNotifier<bool> showSeenDialog = ValueNotifier(false);

    Future<void> fetchSeenUsers() async {
      if (message.readBy.length > 1) {
        final users = await UserService.getUsersByIds(message.readBy);
        seenUsers.value = users;
      }
    }

    Widget seenAvatarsRow = ValueListenableBuilder<List<UserModel>>(
      valueListenable: seenUsers,
      builder: (context, users, _) {
        if (users.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: users.take(5).map((user) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: CircleAvatar(
                radius: 10,
                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                backgroundColor: lightBlue,
                child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                    ? Text(user.initials, style: TextStyle(fontSize: 10, color: primaryBlue))
                    : null,
              ),
            )).toList(),
          ),
        );
      },
    );

    Widget bubble = GestureDetector(
      onLongPress: () => showMenu.value = true,
      onTap: () => showMenu.value = false,
      child: MouseRegion(
        onEnter: (_) => showMenu.value = true,
        onExit: (_) => showMenu.value = false,
        child: ValueListenableBuilder<bool>(
          valueListenable: showMenu,
          builder: (context, menuVisible, child) {
            return Align(
              alignment: alignment,
              child: Container(
                margin: margin,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                decoration: BoxDecoration(
                  color: isMe ? primaryBlue : cardColor,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: isMe
                          ? primaryBlue.withOpacity(0.13)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: isPinned ? Border.all(color: warningOrange, width: 2) : null,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe && _chatRoom?.isClubChat == true)
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundImage: message.senderProfileImage != null && message.senderProfileImage!.isNotEmpty
                                  ? CachedNetworkImageProvider(message.senderProfileImage!)
                                  : null,
                              backgroundColor: lightBlue,
                              child: message.senderProfileImage == null || message.senderProfileImage!.isEmpty
                                  ? Icon(Icons.person, size: 16, color: primaryBlue)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              message.senderName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isPinned)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, color: warningOrange, size: 18),
                          const SizedBox(width: 4),
                          Text('Pinned', style: GoogleFonts.poppins(fontSize: 12, color: warningOrange)),
                        ],
                      ),
                    if (isUnread)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.markunread, color: primaryBlue, size: 18),
                          const SizedBox(width: 4),
                          Text('Unread', style: GoogleFonts.poppins(fontSize: 12, color: primaryBlue)),
                        ],
                      ),
                    messageContent,
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (message.readBy.length > 1) {
                                  await fetchSeenUsers();
                                  showSeenDialog.value = true;
                                }
                              },
                              child: ValueListenableBuilder<bool>(
                                valueListenable: showFullTime,
                                builder: (context, show, _) => Tooltip(
                                  message: show ? fullTimestamp : 'Show full time',
                                  child: Text(
                                    show ? fullTimestamp : shortTime,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isMe ? Colors.white70 : textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                if (message.readBy.length > 1) {
                                  await fetchSeenUsers();
                                  showSeenDialog.value = true;
                                }
                              },
                              child: Tooltip(
                                message: statusText,
                                child: Icon(statusIcon, size: 16, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (menuVisible)
                              _buildMessageActions(message, isMe),
                          ],
                        ),
                      ],
                    ),
                    if (message.readBy.length > 1) seenAvatarsRow,
                    ValueListenableBuilder<bool>(
                      valueListenable: showSeenDialog,
                      builder: (context, show, _) {
                        if (!show) return const SizedBox.shrink();
                        return _buildSeenUsersDialog(seenUsers.value, () => showSeenDialog.value = false);
                      },
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
             .slideX(begin: isMe ? 0.2 : -0.2, duration: 400.ms, curve: Curves.easeOutCubic);
          },
        ),
      ),
    );
    return bubble;
  }

  Widget _buildMessageActions(ChatMessage message, bool isMe) {
    final isAdminOrMod = _currentUser?.isAdmin == true || (_chatRoom?.moderatorIds.contains(_currentUser?.id) ?? false);
    final isPinned = _pinnedMessageIds.contains(message.id);
    final isUnread = _unreadMessageIds.contains(message.id);
    return Container(
      decoration: BoxDecoration(
        color: isMe 
            ? Colors.white.withOpacity(0.15)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_horiz,
          size: 20,
          color: isMe ? Colors.white70 : textTertiary,
        ),
        tooltip: 'More options',
        onSelected: (value) async {
          if (value == 'reply') _onReply(message);
          if (value == 'react') _showReactionPicker(message);
          if (value == 'edit') _onEdit(message);
          if (value == 'delete') _deleteMessage(message);
          if (value == 'copy') {
            await Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Message copied!'), duration: const Duration(seconds: 1)),
            );
          }
          if (value == 'forward') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Forward feature coming soon!'), duration: const Duration(seconds: 1)),
            );
          }
          if (value == 'pin') {
            setState(() => _pinnedMessageIds.add(message.id));
          }
          if (value == 'unpin') {
            setState(() => _pinnedMessageIds.remove(message.id));
          }
          if (value == 'unread') {
            setState(() => _unreadMessageIds.add(message.id));
          }
          if (value == 'read') {
            setState(() => _unreadMessageIds.remove(message.id));
          }
          if (value == 'delete_everyone' && isAdminOrMod) {
            await _deleteMessage(message);
            // Optionally, show a snackbar for delete for everyone
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'reply',
            child: ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: const Text('Reply'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 0,
            ),
          ),
          PopupMenuItem(
            value: 'react',
            child: ListTile(
              leading: const Icon(Icons.tag_faces, color: Colors.orange),
              title: const Text('React'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 0,
            ),
          ),
          if (isMe)
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Edit', style: TextStyle(color: Colors.orange)),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
          if (isMe || isAdminOrMod)
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
          PopupMenuItem(
            value: 'copy',
            child: ListTile(
              leading: const Icon(Icons.copy, color: Colors.teal),
              title: const Text('Copy'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 0,
            ),
          ),
          PopupMenuItem(
            value: 'forward',
            child: ListTile(
              leading: const Icon(Icons.forward, color: Colors.purple),
              title: const Text('Forward'),
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: 0,
            ),
          ),
          if (!isPinned)
            PopupMenuItem(
              value: 'pin',
              child: ListTile(
                leading: const Icon(Icons.push_pin, color: Colors.amber),
                title: const Text('Pin'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
          if (isPinned)
            PopupMenuItem(
              value: 'unpin',
              child: ListTile(
                leading: const Icon(Icons.push_pin, color: Colors.grey),
                title: const Text('Unpin'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
          if (!isUnread)
            PopupMenuItem(
              value: 'unread',
              child: ListTile(
                leading: const Icon(Icons.markunread, color: Colors.blue),
                title: const Text('Mark as Unread'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
          if (isUnread)
            PopupMenuItem(
              value: 'read',
              child: ListTile(
                leading: const Icon(Icons.mark_email_read, color: Colors.green),
                title: const Text('Mark as Read'),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
          if (isAdminOrMod)
            PopupMenuItem(
              value: 'delete_everyone',
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete for Everyone', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
                minLeadingWidth: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernInputField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pendingImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: _pendingImageUrl!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _pendingImageUrl = null),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Emoji button
                Container(
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: primaryBlue,
                      size: 24,
                    ),
                    onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                  ),
                ),
                const SizedBox(width: 12),
                // Attachment button
                Container(
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: primaryBlue,
                      size: 24,
                    ),
                    onPressed: _pickAttachment,
                  ),
                ),
                const SizedBox(width: 12),
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 120,
                      ),
                      child: Scrollbar(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _isEditing ? 'Edit your message...' : 'Type a message...',
                            hintStyle: GoogleFonts.poppins(
                              color: textTertiary,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 16),
                          maxLines: null,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                AnimatedBuilder(
                  animation: _sendButtonController,
                  builder: (context, child) {
                    final canSend = _isTyping || _pendingImageUrl != null;
                    return Transform.scale(
                      scale: 0.8 + (_sendButtonController.value * 0.2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: canSend ? primaryBlue : lightBlue,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isEditing ? Icons.check : Icons.send,
                            color: canSend ? Colors.white : primaryBlue,
                            size: 24,
                          ),
                          onPressed: canSend ? _sendMessage : null,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: EmojiPicker(
        onEmojiSelected: (cat, emoji) => _onEmojiSelected(emoji.emoji),
        config: const Config(),
      ),
    ).animate().slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  PreferredSizeWidget _buildModernAppBar() {
    String name = _chatRoom?.name ?? 'Chat';
    String imageUrl = _chatRoom?.imageUrl ?? '';

    if (_chatRoom?.isDirectChat == true) {
      final otherUserId = _chatRoom?.memberIds.firstWhere((id) => id != _currentUser?.id, orElse: () => '');
      if (otherUserId != null && otherUserId.isNotEmpty) {
        name = _chatRoom?.userNames?[otherUserId] ?? 'User';
        imageUrl = _chatRoom?.userProfileImages?[otherUserId] ?? '';
      }
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryBlue),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
                  backgroundColor: lightBlue,
                  child: (imageUrl.isEmpty && name.isNotEmpty)
                      ? Text(
                          name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // Name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_chatRoom?.description != null && _chatRoom!.isClubChat)
                        Text(
                          _chatRoom!.description!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Action buttons
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.video_call, color: primaryBlue),
                        onPressed: () => _showCallDialog(video: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.call, color: primaryBlue),
                        onPressed: () => _showCallDialog(video: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: primaryBlue),
                        tooltip: 'More options',
                        onSelected: (value) {
                          if (value == 'search') _showSearchInChat();
                          if (value == 'mute') _showMuteDialog();
                          if (value == 'export') _showExportDialog();
                          if (value == 'members') _showMembersDialog();
                          if (value == 'leave') _showLeaveGroupDialog();
                          if (value == 'report') _showReportDialog();
                          if (value == 'photos') _showPhotosDialog();
                          if (value == 'files') _showFilesDialog();
                          if (value == 'links') _showLinksDialog();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'search',
                            child: ListTile(
                              leading: const Icon(Icons.search, color: Colors.blue),
                              title: const Text('Search in chat'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'photos',
                            child: ListTile(
                              leading: const Icon(Icons.photo, color: Colors.purple),
                              title: const Text('View Photos'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'files',
                            child: ListTile(
                              leading: const Icon(Icons.insert_drive_file, color: Colors.green),
                              title: const Text('View Files'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'links',
                            child: ListTile(
                              leading: const Icon(Icons.link, color: Colors.teal),
                              title: const Text('View Links'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'mute',
                            child: ListTile(
                              leading: const Icon(Icons.notifications_off, color: Colors.orange),
                              title: const Text('Mute notifications'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'export',
                            child: ListTile(
                              leading: const Icon(Icons.download, color: Colors.teal),
                              title: const Text('Export chat'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'members',
                            child: ListTile(
                              leading: const Icon(Icons.group, color: Colors.purple),
                              title: const Text('View members'),
                            ),
                          ),
                          if (_chatRoom?.isClubChat == true || _chatRoom?.isDirectChat == false)
                            PopupMenuItem(
                              value: 'leave',
                              child: ListTile(
                                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                                title: const Text('Leave group'),
                              ),
                            ),
                          PopupMenuItem(
                            value: 'report',
                            child: ListTile(
                              leading: const Icon(Icons.report, color: Colors.red),
                              title: const Text('Report'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReactionPicker(ChatMessage message) {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'React to message',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16.0,
                children: reactions.map((r) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ChatService.addOrRemoveReaction(_chatRoom!.id, message.id, r);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        r,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await _showDeleteConfirmation();
    if (confirmed) {
      try {
        await ChatService.deleteMessage(
          chatRoomId: _chatRoom!.id,
          messageId: message.id,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting message: $e'),
              backgroundColor: errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Message',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<List<UserModel>> _fetchUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();
    return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  void _showChatInfoPanel() async {
    if (_chatRoom == null) return;
    final members = await _fetchUsersByIds(_chatRoom!.memberIds);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: _chatRoom!.imageUrl != null && _chatRoom!.imageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(_chatRoom!.imageUrl!)
                                : null,
                            backgroundColor: lightBlue,
                            child: (_chatRoom!.imageUrl == null || _chatRoom!.imageUrl!.isEmpty)
                                ? Text(
                                    _chatRoom!.name.substring(0, 1).toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _chatRoom!.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          if (_chatRoom!.description != null && _chatRoom!.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _chatRoom!.description!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Members',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...members.map((user) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(user.profileImageUrl!)
                                : null,
                            backgroundColor: lightBlue,
                            child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                                ? Icon(Icons.person, color: primaryBlue)
                                : null,
                          ),
                          title: Text(user.fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                          subtitle: Text(user.role.toString().split('.').last, style: GoogleFonts.poppins(fontSize: 12, color: textSecondary)),
                        )),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        if (_currentUser != null && !_currentUser!.isAdmin)
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement leave chat
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Leave chat coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('Leave Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: errorRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCallDialog({required bool video}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          video ? 'Video Call' : 'Audio Call',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          video
              ? 'Video call feature coming soon!'
              : 'Audio call feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, {bool timeOnly = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (timeOnly) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    
    if (messageDate == today) {
      return 'Today at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showSearchInChat() {
    showDialog(context: context, builder: (context) => AlertDialog(title: Text('Search in chat'), content: Text('Search feature coming soon.')));
  }

  void _showMuteDialog() {
    setState(() => _isMuted = !_isMuted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isMuted ? 'Chat muted' : 'Chat unmuted')),
    );
  }

  void _showExportDialog() async {
    final buffer = StringBuffer();
    for (final m in _messages) {
      final time = _formatTimestamp(m.timestamp);
      buffer.writeln('[${m.senderName} | $time]: ${m.content}');
    }
    final text = buffer.toString();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/chat_export.txt');
    await file.writeAsString(text);
    await Share.shareXFiles([XFile(file.path)], text: 'Chat export');
  }

  void _showLeaveGroupDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to leave this group?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm == true && _chatRoom != null && _currentUser != null) {
      final memberIds = List<String>.from(_chatRoom!.memberIds);
      memberIds.remove(_currentUser!.id);
      await FirebaseFirestore.instance.collection('chat_rooms').doc(_chatRoom!.id).update({'memberIds': memberIds});
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You left the group.')));
    }
  }

  void _showReportDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Describe the issue...'),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Report', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('chat_reports').add({
        'chatRoomId': _chatRoom?.id,
        'userId': _currentUser?.id,
        'userName': _currentUser?.displayName,
        'description': controller.text.trim(),
        'createdAt': DateTime.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report submitted.')));
    }
  }

  void _showPhotosDialog() {
    final images = _messages.where((m) => m.type == MessageType.image && m.imageUrl != null).toList();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 350,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Photos', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: images.isEmpty
                  ? Center(child: Text('No photos found.'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: images.length,
                      itemBuilder: (context, i) {
                        final img = images[i];
                        return GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: CachedNetworkImage(imageUrl: img.imageUrl!, fit: BoxFit.contain),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(imageUrl: img.imageUrl!, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilesDialog() {
    final files = _messages.where((m) => m.type == MessageType.file && m.fileUrl != null).toList();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 350,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Files', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: files.isEmpty
                  ? Center(child: Text('No files found.'))
                  : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, i) {
                        final file = files[i];
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                          title: Text(file.fileName ?? 'File', style: GoogleFonts.poppins()),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () async {
                              final url = file.fileUrl!;
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinksDialog() {
    final urlRegex = RegExp(r"(https?://[\w\-._~:/?#[\]@!$&'()*+,;=%.]+)", caseSensitive: false);
    final links = _messages
      .where((m) => m.type == MessageType.text && urlRegex.hasMatch(m.content))
      .expand((m) => urlRegex.allMatches(m.content).map((match) => match.group(0)!))
      .toList();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 350,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Links', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: links.isEmpty
                  ? Center(child: Text('No links found.'))
                  : ListView.builder(
                      itemCount: links.length,
                      itemBuilder: (context, i) {
                        final link = links[i];
                        return ListTile(
                          leading: const Icon(Icons.link, color: Colors.teal),
                          title: Text(link, style: GoogleFonts.poppins(color: Colors.blue)),
                          onTap: () async {
                            if (await canLaunchUrl(Uri.parse(link))) {
                              await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
                            }
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMembersDialog() async {
    final users = await UserService.getUsersByIds(_chatRoom?.memberIds ?? []);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 350,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Members', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: users.isEmpty
                  ? Center(child: Text('No members found.'))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final user = users[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(user.profileImageUrl!)
                                : null,
                            backgroundColor: lightBlue,
                            child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                                ? Text(user.initials, style: TextStyle(fontSize: 12, color: primaryBlue))
                                : null,
                          ),
                          title: Text(user.displayName, style: GoogleFonts.poppins()),
                          subtitle: Text(user.email, style: GoogleFonts.poppins(fontSize: 12)),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeenUsersDialog(List<UserModel> users, VoidCallback onClose) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Seen by', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
            const SizedBox(height: 8),
            ...users.map((user) => ListTile(
              leading: CircleAvatar(
                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                backgroundColor: lightBlue,
                child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                    ? Text(user.initials, style: TextStyle(fontSize: 12, color: primaryBlue))
                    : null,
              ),
              title: Text(user.displayName, style: GoogleFonts.poppins()),
            )),
          ],
        ),
      ),
    );
  }
}
