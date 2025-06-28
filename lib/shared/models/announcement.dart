import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

enum AnnouncementType {
  general,
  academic,
  event,
  emergency,
  reminder,
  update,
  news,
  policy,
  other,
}

enum AnnouncementVisibility {
  public,
  private,
  department,
  club,
}

enum AnnouncementStatus {
  draft,
  pending,
  approved,
  rejected,
  active,
  archived,
}

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final AnnouncementType type;
  final AnnouncementVisibility visibility;
  final AnnouncementStatus status;
  final String clubId;
  final String clubName;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> tags;
  final List<String> readByIds;
  final List<String> importantForIds;
  final bool isImportant;
  final bool isPinned;
  final String? externalLink;
  final Department? department;
  final Campus? campus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final Map<String, dynamic> metadata;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.type,
    this.visibility = AnnouncementVisibility.club,
    this.status = AnnouncementStatus.draft,
    required this.clubId,
    required this.clubName,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.startDate,
    this.endDate,
    this.tags = const [],
    this.readByIds = const [],
    this.importantForIds = const [],
    this.isImportant = false,
    this.isPinned = false,
    this.externalLink,
    this.department,
    this.campus,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.metadata = const {},
  });

  bool get isDraft => status == AnnouncementStatus.draft;
  bool get isPending => status == AnnouncementStatus.pending;
  bool get isApproved => status == AnnouncementStatus.approved;
  bool get isRejected => status == AnnouncementStatus.rejected;
  bool get isActive => status == AnnouncementStatus.active;
  bool get isArchived => status == AnnouncementStatus.archived;
  bool get isPublic => visibility == AnnouncementVisibility.public;
  bool get isPrivate => visibility == AnnouncementVisibility.private;
  bool get isDepartmentOnly => visibility == AnnouncementVisibility.department;
  bool get isClubOnly => visibility == AnnouncementVisibility.club;
  bool get needsApproval => visibility == AnnouncementVisibility.public && !isApproved;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool isReadByUser(String userId) => readByIds.contains(userId);
  bool isImportantForUser(String userId) => importantForIds.contains(userId);

  int get readCount => readByIds.length;
  int get importantForCount => importantForIds.length;

  // Check if user can view this announcement
  bool canBeViewedBy(UserModel user) {
    if (isPublic && isApproved) return true;
    if (user.isAdmin) return true;
    if (isDepartmentOnly && user.department == department && isApproved) return true;
    if (isClubOnly) {
      return user.isMemberOf(clubId) || user.isModeratorOf(clubId) || user.isAdmin;
    }
    if (isPrivate) {
      return user.isMemberOf(clubId) || user.isModeratorOf(clubId) || user.isAdmin;
    }
    return false;
  }

  // Check if user can create announcements
  bool canBeCreatedBy(UserModel user) {
    if (user.isAdmin) return true;
    if (user.isModeratorOf(clubId)) return true;
    return false;
  }

  // Check if user can edit this announcement
  bool canBeEditedBy(UserModel user) {
    if (user.isAdmin) return true;
    if (user.isModeratorOf(clubId) && createdBy == user.id) return true;
    return false;
  }

  // Check if user can delete this announcement
  bool canBeDeletedBy(UserModel user) {
    if (user.isAdmin) return true;
    if (user.isModeratorOf(clubId) && createdBy == user.id && isDraft) return true;
    return false;
  }

  // Check if user can approve this announcement
  bool canBeApprovedBy(UserModel user) {
    if (user.isAdmin) return true;
    if (isPublic && user.canApprovePublicContent()) return true;
    return false;
  }

  // Check if user can mark as read
  bool canBeMarkedAsReadBy(UserModel user) {
    return canBeViewedBy(user) && !isReadByUser(user.id);
  }

  // Check if user can mark as important
  bool canBeMarkedAsImportantBy(UserModel user) {
    return canBeViewedBy(user) && !isImportantForUser(user.id);
  }

  // Get type name
  String get typeName {
    switch (type) {
      case AnnouncementType.general:
        return 'General';
      case AnnouncementType.academic:
        return 'Academic';
      case AnnouncementType.event:
        return 'Event';
      case AnnouncementType.emergency:
        return 'Emergency';
      case AnnouncementType.reminder:
        return 'Reminder';
      case AnnouncementType.update:
        return 'Update';
      case AnnouncementType.news:
        return 'News';
      case AnnouncementType.policy:
        return 'Policy';
      case AnnouncementType.other:
        return 'Other';
      default:
        return 'Other';
    }
  }

  // Get visibility name
  String get visibilityName {
    switch (visibility) {
      case AnnouncementVisibility.public:
        return 'Public';
      case AnnouncementVisibility.private:
        return 'Private';
      case AnnouncementVisibility.department:
        return 'Department';
      case AnnouncementVisibility.club:
        return 'Club';
      default:
        return 'Club';
    }
  }

  // Get status name
  String get statusName {
    switch (status) {
      case AnnouncementStatus.draft:
        return 'Draft';
      case AnnouncementStatus.pending:
        return 'Pending Approval';
      case AnnouncementStatus.approved:
        return 'Approved';
      case AnnouncementStatus.rejected:
        return 'Rejected';
      case AnnouncementStatus.active:
        return 'Active';
      case AnnouncementStatus.archived:
        return 'Archived';
      default:
        return 'Draft';
    }
  }

  // Get department name
  String get departmentName {
    if (department == null) return 'Not specified';
    switch (department!) {
      case Department.cas:
        return 'College of Arts and Sciences';
      case Department.cbe:
        return 'College of Business and Entrepreneurship';
      case Department.coe:
        return 'College of Education';
      case Department.coeng:
        return 'College of Engineering';
      case Department.cot:
        return 'College of Technology';
      case Department.coa:
        return 'College of Agriculture';
      case Department.cof:
        return 'College of Fisheries';
      case Department.cofes:
        return 'College of Forestry and Environmental Science';
      case Department.com:
        return 'College of Medicine';
      case Department.con:
        return 'College of Nursing';
      case Department.coph:
        return 'College of Pharmacy';
   
      default:
        return 'Not specified';
    }
  }

  // Get campus name
  String get campusName {
    if (campus == null) return 'Not specified';
    switch (campus!) {
      case Campus.main:
        return 'Main Campus (Sogod)';
      case Campus.salcedo:
        return 'Salcedo Campus';
      case Campus.sanJuan:
        return 'San Juan Campus';
      case Campus.hinunangan:
        return 'Hinunangan Campus';
      case Campus.hinundayan:
        return 'Hinundayan Campus';
      case Campus.saintBernard:
        return 'Saint Bernard Campus';
      case Campus.sanMiguel:
        return 'San Miguel Campus';
      case Campus.liloan:
        return 'Liloan Campus';
      case Campus.sanFrancisco:
        return 'San Francisco Campus';
      case Campus.sanRicardo:
        return 'San Ricardo Campus';
      case Campus.anahawan:
        return 'Anahawan Campus';
      case Campus.silago:
        return 'Silago Campus';
      case Campus.santaRita:
        return 'Santa Rita Campus';
      case Campus.macrohon:
        return 'Macrohon Campus';
      case Campus.malitbog:
        return 'Malitbog Campus';
      case Campus.tomasOppus:
        return 'Tomas Oppus Campus';
      case Campus.limasawa:
        return 'Limasawa Campus';
      case Campus.padreBurgos:
        return 'Padre Burgos Campus';
      default:
        return 'Not specified';
    }
  }

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      type: AnnouncementTypeExtension.fromString(data['type'] ?? ''),
      visibility: AnnouncementVisibility.values.firstWhere(
        (visibility) => visibility.toString() == 'AnnouncementVisibility.${data['visibility'] ?? 'club'}',
        orElse: () => AnnouncementVisibility.club,
      ),
      status: AnnouncementStatus.values.firstWhere(
        (status) => status.toString() == 'AnnouncementStatus.${data['status'] ?? 'draft'}',
        orElse: () => AnnouncementStatus.draft,
      ),
      clubId: data['clubId'] ?? '',
      clubName: data['clubName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      startDate: data['startDate'] != null ? (data['startDate'] as Timestamp).toDate() : null,
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      tags: List<String>.from(data['tags'] ?? []),
      readByIds: List<String>.from(data['readByIds'] ?? []),
      importantForIds: List<String>.from(data['importantForIds'] ?? []),
      isImportant: data['isImportant'] ?? false,
      isPinned: data['isPinned'] ?? false,
      externalLink: data['externalLink'],
      department: data['department'] != null 
          ? Department.values.firstWhere(
              (dept) => dept.toString() == 'Department.${data['department']}',
              orElse: () => Department.cas,
            )
          : null,
      campus: data['campus'] != null 
          ? Campus.values.firstWhere(
              (campus) => campus.toString() == 'Campus.${data['campus']}',
              orElse: () => Campus.main,
            )
          : null,
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate() : null,
      rejectionReason: data['rejectionReason'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'type': type.toString().split('.').last,
      'visibility': visibility.toString().split('.').last,
      'status': status.toString().split('.').last,
      'clubId': clubId,
      'clubName': clubName,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'tags': tags,
      'readByIds': readByIds,
      'importantForIds': importantForIds,
      'isImportant': isImportant,
      'isPinned': isPinned,
      'externalLink': externalLink,
      'department': department?.toString().split('.').last,
      'campus': campus?.toString().split('.').last,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'metadata': metadata,
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    AnnouncementType? type,
    AnnouncementVisibility? visibility,
    AnnouncementStatus? status,
    String? clubId,
    String? clubName,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    List<String>? readByIds,
    List<String>? importantForIds,
    bool? isImportant,
    bool? isPinned,
    String? externalLink,
    Department? department,
    Campus? campus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      readByIds: readByIds ?? this.readByIds,
      importantForIds: importantForIds ?? this.importantForIds,
      isImportant: isImportant ?? this.isImportant,
      isPinned: isPinned ?? this.isPinned,
      externalLink: externalLink ?? this.externalLink,
      department: department ?? this.department,
      campus: campus ?? this.campus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
    );
  }
}

extension AnnouncementTypeExtension on AnnouncementType {
  static AnnouncementType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'general':
        return AnnouncementType.general;
      case 'academic':
        return AnnouncementType.academic;
      case 'event':
        return AnnouncementType.event;
      case 'emergency':
        return AnnouncementType.emergency;
      case 'reminder':
        return AnnouncementType.reminder;
      case 'update':
        return AnnouncementType.update;
      case 'news':
        return AnnouncementType.news;
      case 'policy':
        return AnnouncementType.policy;
      case 'other':
        return AnnouncementType.other;
      default:
        return AnnouncementType.general;
    }
  }
} 