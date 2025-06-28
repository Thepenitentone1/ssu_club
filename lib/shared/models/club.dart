import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

enum ClubType {
  academic,
  cultural,
  sports,
  religious,
  professional,
  social,
  technical,
  environmental,
  health,
  leadership,
  service,
  other,
}

enum ClubVisibility {
  public,
  private,
  department,
}

enum ClubStatus {
  active,
  inactive,
  pending,
  suspended,
}

class ClubModel {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final List<String> tags;
  final ClubType type;
  final ClubVisibility visibility;
  final ClubStatus status;
  final Department department;
  final Campus campus;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> memberIds;
  final List<String> moderatorIds;
  final List<String> adminIds;
  final Map<String, dynamic> settings;
  final bool requiresApproval;
  final bool isPublicContentApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final int memberCount;
  final int eventCount;
  final int announcementCount;

  ClubModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    this.tags = const [],
    required this.type,
    this.visibility = ClubVisibility.department,
    this.status = ClubStatus.active,
    required this.department,
    required this.campus,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberIds = const [],
    this.moderatorIds = const [],
    this.adminIds = const [],
    this.settings = const {},
    this.requiresApproval = true,
    this.isPublicContentApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.memberCount = 0,
    this.eventCount = 0,
    this.announcementCount = 0,
  });

  bool get isActive => status == ClubStatus.active;
  bool get isPending => status == ClubStatus.pending;
  bool get isSuspended => status == ClubStatus.suspended;
  bool get isPublic => visibility == ClubVisibility.public;
  bool get isPrivate => visibility == ClubVisibility.private;
  bool get isDepartmentOnly => visibility == ClubVisibility.department;
  bool get isApproved => isPublicContentApproved;
  bool get needsApproval => requiresApproval && !isPublicContentApproved;

  // Check if user can view this club
  bool canBeViewedBy(UserModel user) {
    if (isPublic) return true;
    if (user.isAdmin) return true;
    if (isDepartmentOnly && user.department == department) return true;
    if (isPrivate) {
      return user.isMemberOf(id) || user.isModeratorOf(id) || user.isAdmin;
    }
    return false;
  }

  // Check if user can join this club
  bool canBeJoinedBy(UserModel user) {
    if (!isActive) return false;
    if (user.isMemberOf(id)) return false;
    if (isPrivate && !user.isAdmin) return false;
    return true;
  }

  // Check if user can moderate this club
  bool canBeModeratedBy(UserModel user) {
    return user.isAdmin || user.isModeratorOf(id);
  }

  // Check if user can manage this club
  bool canBeManagedBy(UserModel user) {
    return user.isAdmin || user.isModeratorOf(id);
  }

  // Check if user can create content in this club
  bool canCreateContent(UserModel user) {
    if (!isActive) return false;
    if (user.isAdmin) return true;
    if (user.isModeratorOf(id)) return true;
    if (user.isMemberOf(id) && !requiresApproval) return true;
    return false;
  }

  // Check if user can approve content in this club
  bool canApproveContent(UserModel user) {
    return user.isAdmin || user.isModeratorOf(id);
  }

  // Get department name
  String get departmentName {
    switch (department) {
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
    switch (campus) {
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

  // Get type name
  String get typeName {
    switch (type) {
      case ClubType.academic:
        return 'Academic';
      case ClubType.cultural:
        return 'Cultural';
      case ClubType.sports:
        return 'Sports';
      case ClubType.religious:
        return 'Religious';
      case ClubType.professional:
        return 'Professional';
      case ClubType.social:
        return 'Social';
      case ClubType.technical:
        return 'Technical';
      case ClubType.environmental:
        return 'Environmental';
      case ClubType.health:
        return 'Health';
      case ClubType.leadership:
        return 'Leadership';
      case ClubType.service:
        return 'Service';
      case ClubType.other:
        return 'Other';
      default:
        return 'Other';
    }
  }

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ClubModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      bannerUrl: data['bannerUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      type: ClubType.values.firstWhere(
        (type) => type.toString() == 'ClubType.${data['type'] ?? 'other'}',
        orElse: () => ClubType.other,
      ),
      visibility: ClubVisibility.values.firstWhere(
        (visibility) => visibility.toString() == 'ClubVisibility.${data['visibility'] ?? 'department'}',
        orElse: () => ClubVisibility.department,
      ),
      status: ClubStatus.values.firstWhere(
        (status) => status.toString() == 'ClubStatus.${data['status'] ?? 'active'}',
        orElse: () => ClubStatus.active,
      ),
      department: Department.values.firstWhere(
        (dept) => dept.toString() == 'Department.${data['department'] ?? 'cas'}',
        orElse: () => Department.cas,
      ),
      campus: Campus.values.firstWhere(
        (campus) => campus.toString() == 'Campus.${data['campus'] ?? 'main'}',
        orElse: () => Campus.main,
      ),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      requiresApproval: data['requiresApproval'] ?? true,
      isPublicContentApproved: data['isPublicContentApproved'] ?? false,
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate() : null,
      rejectionReason: data['rejectionReason'],
      memberCount: data['memberCount'] ?? 0,
      eventCount: data['eventCount'] ?? 0,
      announcementCount: data['announcementCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'tags': tags,
      'type': type.toString().split('.').last,
      'visibility': visibility.toString().split('.').last,
      'status': status.toString().split('.').last,
      'department': department.toString().split('.').last,
      'campus': campus.toString().split('.').last,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'memberIds': memberIds,
      'moderatorIds': moderatorIds,
      'adminIds': adminIds,
      'settings': settings,
      'requiresApproval': requiresApproval,
      'isPublicContentApproved': isPublicContentApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'memberCount': memberCount,
      'eventCount': eventCount,
      'announcementCount': announcementCount,
    };
  }

  ClubModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    List<String>? tags,
    ClubType? type,
    ClubVisibility? visibility,
    ClubStatus? status,
    Department? department,
    Campus? campus,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? memberIds,
    List<String>? moderatorIds,
    List<String>? adminIds,
    Map<String, dynamic>? settings,
    bool? requiresApproval,
    bool? isPublicContentApproved,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    int? memberCount,
    int? eventCount,
    int? announcementCount,
  }) {
    return ClubModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      department: department ?? this.department,
      campus: campus ?? this.campus,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberIds: memberIds ?? this.memberIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      adminIds: adminIds ?? this.adminIds,
      settings: settings ?? this.settings,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      isPublicContentApproved: isPublicContentApproved ?? this.isPublicContentApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      memberCount: memberCount ?? this.memberCount,
      eventCount: eventCount ?? this.eventCount,
      announcementCount: announcementCount ?? this.announcementCount,
    );
  }
}

class ClubOfficer {
  final String name;
  final String position;
  final String? imageUrl;
  final String? contactInfo;

  ClubOfficer({
    required this.name,
    required this.position,
    this.imageUrl,
    this.contactInfo,
  });

  factory ClubOfficer.fromMap(Map<String, dynamic> map) {
    return ClubOfficer(
      name: map['name'] ?? '',
      position: map['position'] ?? '',
      imageUrl: map['imageUrl'],
      contactInfo: map['contactInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'imageUrl': imageUrl,
      'contactInfo': contactInfo,
    };
  }
}

class ClubApplication {
  final String id;
  final String clubId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userProfileImage;
  final String? message;
  final MembershipStatus status;
  final DateTime appliedAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? rejectionReason;
  final Map<String, dynamic>? additionalData;

  ClubApplication({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userProfileImage,
    this.message,
    this.status = MembershipStatus.pending,
    required this.appliedAt,
    this.processedAt,
    this.processedBy,
    this.rejectionReason,
    this.additionalData,
  });

  bool get isPending => status == MembershipStatus.pending;
  bool get isApproved => status == MembershipStatus.approved;
  bool get isRejected => status == MembershipStatus.rejected;

  factory ClubApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ClubApplication(
      id: doc.id,
      clubId: data['clubId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userProfileImage: data['userProfileImage'],
      message: data['message'],
      status: MembershipStatus.values.firstWhere(
        (status) => status.toString() == 'MembershipStatus.${data['status'] ?? 'pending'}',
        orElse: () => MembershipStatus.pending,
      ),
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null ? (data['processedAt'] as Timestamp).toDate() : null,
      processedBy: data['processedBy'],
      rejectionReason: data['rejectionReason'],
      additionalData: data['additionalData'] != null 
          ? Map<String, dynamic>.from(data['additionalData']) 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clubId': clubId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userProfileImage': userProfileImage,
      'message': message,
      'status': status.toString().split('.').last,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'processedBy': processedBy,
      'rejectionReason': rejectionReason,
      'additionalData': additionalData,
    };
  }

  ClubApplication copyWith({
    String? id,
    String? clubId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userProfileImage,
    String? message,
    MembershipStatus? status,
    DateTime? appliedAt,
    DateTime? processedAt,
    String? processedBy,
    String? rejectionReason,
    Map<String, dynamic>? additionalData,
  }) {
    return ClubApplication(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      message: message ?? this.message,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      additionalData: additionalData ?? this.additionalData,
    );
  }
} 