import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType {
  club,
  direct,
  group,
}

enum MessageType {
  text,
  image,
  file,
  announcement,
  event,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderProfileImage;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final Map<String, dynamic>? metadata;
  final bool isEdited;
  final DateTime? editedAt;
  final List<String> readBy;
  final Map<String, List<String>> reactions;
  final String? replyToMessageId;
  final String? replyToMessageContent;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderProfileImage,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.metadata,
    this.isEdited = false,
    this.editedAt,
    this.readBy = const [],
    this.reactions = const {},
    this.replyToMessageId,
    this.replyToMessageContent,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderProfileImage: data['senderProfileImage'],
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (type) => type.toString() == 'MessageType.${data['type'] ?? 'text'}',
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata']) 
          : null,
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null ? (data['editedAt'] as Timestamp).toDate() : null,
      readBy: List<String>.from(data['readBy'] ?? []),
      reactions: data['reactions'] is Map
          ? (data['reactions'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                List<String>.from(value as List? ?? []),
              ),
            )
          : {},
      replyToMessageId: data['replyToMessageId'],
      replyToMessageContent: data['replyToMessageContent'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImage': senderProfileImage,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'metadata': metadata,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'readBy': readBy,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToMessageContent': replyToMessageContent,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderProfileImage,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    Map<String, dynamic>? metadata,
    bool? isEdited,
    DateTime? editedAt,
    List<String>? readBy,
    Map<String, List<String>>? reactions,
    String? replyToMessageId,
    String? replyToMessageContent,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfileImage: senderProfileImage ?? this.senderProfileImage,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      metadata: metadata ?? this.metadata,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      readBy: readBy ?? this.readBy,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessageContent: replyToMessageContent ?? this.replyToMessageContent,
    );
  }
}

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final ChatType type;
  final String? clubId;
  final String? clubName;
  final List<String> memberIds;
  final List<String> moderatorIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final String? lastMessageSender;
  final int messageCount;
  final bool isActive;
  final Map<String, dynamic>? settings;
  final Map<String, String?>? userProfileImages;
  final Map<String, String>? userNames;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.type,
    this.clubId,
    this.clubName,
    this.memberIds = const [],
    this.moderatorIds = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageSender,
    this.messageCount = 0,
    this.isActive = true,
    this.settings,
    this.userProfileImages,
    this.userNames,
  });

  bool get isClubChat => type == ChatType.club;
  bool get isDirectChat => type == ChatType.direct;
  bool get isGroupChat => type == ChatType.group;

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      type: ChatType.values.firstWhere(
        (type) => type.toString() == 'ChatType.${data['type'] ?? 'club'}',
        orElse: () => ChatType.club,
      ),
      clubId: data['clubId'],
      clubName: data['clubName'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastMessageAt: data['lastMessageAt'] != null ? (data['lastMessageAt'] as Timestamp).toDate() : null,
      lastMessage: data['lastMessage'],
      lastMessageSender: data['lastMessageSender'],
      messageCount: data['messageCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      settings: data['settings'] != null ? Map<String, dynamic>.from(data['settings']) : null,
      userProfileImages: data['userProfileImages'] != null ? Map<String, String?>.from(data['userProfileImages']) : null,
      userNames: data['userNames'] != null ? Map<String, String>.from(data['userNames']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.toString().split('.').last,
      'clubId': clubId,
      'clubName': clubName,
      'memberIds': memberIds,
      'moderatorIds': moderatorIds,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'messageCount': messageCount,
      'isActive': isActive,
      'settings': settings,
      'userProfileImages': userProfileImages,
      'userNames': userNames,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    ChatType? type,
    String? clubId,
    String? clubName,
    List<String>? memberIds,
    List<String>? moderatorIds,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? lastMessageSender,
    int? messageCount,
    bool? isActive,
    Map<String, dynamic>? settings,
    Map<String, String?>? userProfileImages,
    Map<String, String>? userNames,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      memberIds: memberIds ?? this.memberIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      messageCount: messageCount ?? this.messageCount,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      userProfileImages: userProfileImages ?? this.userProfileImages,
      userNames: userNames ?? this.userNames,
    );
  }
} 