import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/user.dart';
import '../../shared/models/club.dart';
import '../../shared/models/chat.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get or create club chat room
  static Future<ChatRoom> getOrCreateClubChat(String clubId) async {
    try {
      // Check if chat room already exists
      final existingChat = await _firestore
          .collection('chat_rooms')
          .where('clubId', isEqualTo: clubId)
          .where('type', isEqualTo: ChatType.club.toString().split('.').last)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return ChatRoom.fromFirestore(existingChat.docs.first);
      }

      // Get club details
      final clubDoc = await _firestore.collection('clubs').doc(clubId).get();
      if (!clubDoc.exists) throw Exception('Club not found');

      final club = ClubModel.fromFirestore(clubDoc);

      // Create new chat room
      final chatRoom = ChatRoom(
        id: '', // Will be set by Firestore
        name: '${club.name} Chat',
        description: 'Chat room for ${club.name} members',
        type: ChatType.club,
        clubId: clubId,
        clubName: club.name,
        memberIds: club.memberIds,
        moderatorIds: club.moderatorIds,
        createdBy: club.createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('chat_rooms').add(chatRoom.toFirestore());
      return chatRoom.copyWith(id: docRef.id);
    } catch (e) {
      print('Error getting or creating club chat: $e');
      rethrow;
    }
  }

  // Get or create direct chat room
  static Future<ChatRoom> getOrCreateDirectChat(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Generate a consistent chat room ID for the user pair
      final chatRoomId = _generateDirectChatId(currentUser.uid, otherUserId);

      // Check if chat room already exists
      final chatRoomDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
      if (chatRoomDoc.exists) {
        return ChatRoom.fromFirestore(chatRoomDoc);
      }

      // Get user details
      final currentUserModel = await _getCurrentUserModel();
      final otherUserModel = await _getUserModel(otherUserId);
      if (currentUserModel == null || otherUserModel == null) {
        throw Exception('One or more users not found');
      }

      // Create new chat room for direct messages
      final chatRoom = ChatRoom(
        id: chatRoomId,
        name: otherUserModel.fullName, // The other user's name
        type: ChatType.direct,
        memberIds: [currentUser.uid, otherUserId],
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Add any other relevant fields for DM
        userProfileImages: {
          currentUser.uid: currentUserModel.profileImageUrl,
          otherUserId: otherUserModel.profileImageUrl,
        },
        userNames: {
          currentUser.uid: currentUserModel.fullName,
          otherUserId: otherUserModel.fullName,
        },
      );

      await _firestore.collection('chat_rooms').doc(chatRoomId).set(chatRoom.toFirestore());
      return chatRoom;
    } catch (e) {
      print('Error getting or creating direct chat: $e');
      rethrow;
    }
  }

  // Send message
  static Future<void> sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    String? replyToMessageContent,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userModel = await _getCurrentUserModel();
      if (userModel == null) throw Exception('User not found');

      // Check if user can send messages in this chat room
      final canSend = await _canUserSendMessage(chatRoomId, userModel);
      if (!canSend) throw Exception('Cannot send messages in this chat room');

      final message = ChatMessage(
        id: '', // Will be set by Firestore
        senderId: user.uid,
        senderName: userModel.fullName,
        senderProfileImage: userModel.profileImageUrl,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        fileName: fileName,
        metadata: metadata,
        readBy: [user.uid],
        replyToMessageId: replyToMessageId,
        replyToMessageContent: replyToMessageContent,
      );

      // Add message to chat room
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toFirestore());

      // Update chat room metadata
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': content,
        'lastMessageSender': userModel.fullName,
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'messageCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a chat room
  static Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList()
            .reversed
            .toList());
  }

  // Get user's chat rooms (including club chats they're members of)
  static Stream<List<ChatRoom>> getUserChatRooms() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chat_rooms')
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();

      // Filter chat rooms where user is a member
      final userModel = await _getCurrentUserModel();
      if (userModel == null) return [];

      return chatRooms.where((chatRoom) {
        // Check if user is directly a member of the chat room
        if (chatRoom.memberIds.contains(user.uid)) return true;
        
        // For club chats, check if user is a member of the club
        if (chatRoom.isClubChat && chatRoom.clubId != null) {
          return userModel.isMemberOf(chatRoom.clubId!);
        }
        
        return false;
      }).toList();
    });
  }

  // Mark message as read
  static Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([user.uid]),
      });
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Edit message
  static Future<void> editMessage({
    required String chatRoomId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user can edit this message
      final messageDoc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) throw Exception('Message not found');

      final message = ChatMessage.fromFirestore(messageDoc);
      if (message.senderId != user.uid) {
        throw Exception('Cannot edit messages from other users');
      }

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error editing message: $e');
      rethrow;
    }
  }

  // Delete message (moderator/admin only)
  static Future<void> deleteMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userModel = await _getCurrentUserModel();
      if (userModel == null) throw Exception('User not found');

      // Check if user can delete messages in this chat room
      final canDelete = await _canUserDeleteMessages(chatRoomId, userModel);
      if (!canDelete) throw Exception('Cannot delete messages in this chat room');

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Add reaction to message
  static Future<void> addReaction({
    required String chatRoomId,
    required String messageId,
    required String reaction,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions': FieldValue.arrayUnion([reaction]),
      });
    } catch (e) {
      print('Error adding reaction: $e');
    }
  }

  // Add or remove a reaction from a message
  static Future<void> addOrRemoveReaction(String chatRoomId, String messageId, String reaction) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageRef = _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final messageDoc = await transaction.get(messageRef);
        if (!messageDoc.exists) throw Exception('Message not found');

        final message = ChatMessage.fromFirestore(messageDoc);
        final newReactions = Map<String, List<String>>.from(message.reactions);
        
        if (newReactions.containsKey(reaction) && newReactions[reaction]!.contains(user.uid)) {
          // User has already reacted, so remove reaction
          newReactions[reaction]!.remove(user.uid);
          if (newReactions[reaction]!.isEmpty) {
            newReactions.remove(reaction);
          }
        } else {
          // User has not reacted, so add reaction
          newReactions.putIfAbsent(reaction, () => []);
          newReactions[reaction]!.add(user.uid);
        }

        transaction.update(messageRef, {'reactions': newReactions});
      });
    } catch (e) {
      print('Error adding reaction: $e');
      rethrow;
    }
  }

  // Check if current user is the sender of a message
  static Future<bool> isMessageSender(String chatRoomId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final messageDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').doc(messageId).get();
    if (!messageDoc.exists) return false;

    return messageDoc.data()?['senderId'] == user.uid;
  }

  // Helper methods
  static Future<UserModel?> _getCurrentUserModel() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting current user model: $e');
      return null;
    }
  }

  static Future<bool> _canUserSendMessage(String chatRoomId, UserModel user) async {
    try {
      final chatDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
      if (!chatDoc.exists) return false;

      final chatRoom = ChatRoom.fromFirestore(chatDoc);

      // Check if user is a member
      if (!chatRoom.memberIds.contains(user.id)) return false;

      // For club chats, check if user is still a member of the club
      if (chatRoom.isClubChat && chatRoom.clubId != null) {
        return user.isMemberOf(chatRoom.clubId!);
      }

      return true;
    } catch (e) {
      print('Error checking if user can send message: $e');
      return false;
    }
  }

  static Future<bool> _canUserDeleteMessages(String chatRoomId, UserModel user) async {
    try {
      final chatDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
      if (!chatDoc.exists) return false;

      final chatRoom = ChatRoom.fromFirestore(chatDoc);

      // Check if user is a moderator or admin
      if (user.isAdmin) return true;
      if (chatRoom.moderatorIds.contains(user.id)) return true;
      if (chatRoom.createdBy == user.id) return true;

      // For club chats, check if user is a moderator of the club
      if (chatRoom.isClubChat && chatRoom.clubId != null) {
        return user.canModerate(chatRoom.clubId!);
      }

      return false;
    } catch (e) {
      print('Error checking if user can delete messages: $e');
      return false;
    }
  }

  // Create chat room for a club (called when club is created or user joins)
  static Future<void> createClubChatRoom(String clubId) async {
    try {
      // Check if chat room already exists
      final existingChat = await _firestore
          .collection('chat_rooms')
          .where('clubId', isEqualTo: clubId)
          .where('type', isEqualTo: ChatType.club.toString().split('.').last)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        print('Chat room already exists for club $clubId');
        return;
      }

      // Get club details
      final clubDoc = await _firestore.collection('clubs').doc(clubId).get();
      if (!clubDoc.exists) throw Exception('Club not found');

      final club = ClubModel.fromFirestore(clubDoc);

      // Create new chat room
      final chatRoom = ChatRoom(
        id: '', // Will be set by Firestore
        name: '${club.name} Chat',
        description: 'Chat room for ${club.name} members',
        type: ChatType.club,
        clubId: clubId,
        clubName: club.name,
        memberIds: club.memberIds,
        moderatorIds: club.moderatorIds,
        createdBy: club.createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('chat_rooms').add(chatRoom.toFirestore());
      print('Created chat room for club ${club.name}');
    } catch (e) {
      print('Error creating club chat room: $e');
      rethrow;
    }
  }

  // Update chat room members when club membership changes
  static Future<void> updateClubChatMembers(String clubId, List<String> memberIds) async {
    try {
      final chatQuery = await _firestore
          .collection('chat_rooms')
          .where('clubId', isEqualTo: clubId)
          .where('type', isEqualTo: ChatType.club.toString().split('.').last)
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) {
        final chatDoc = chatQuery.docs.first;
        await chatDoc.reference.update({
          'memberIds': memberIds,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        print('Updated chat room members for club $clubId');
      }
    } catch (e) {
      print('Error updating chat room members: $e');
    }
  }

  // Helper to generate a consistent ID for direct chats
  static String _generateDirectChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 ? '$userId1-$userId2' : '$userId2-$userId1';
  }

  // Helper to get a specific user model
  static Future<UserModel?> _getUserModel(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  // Get a single chat room by its ID
  static Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
      return doc.exists ? ChatRoom.fromFirestore(doc) : null;
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }
} 