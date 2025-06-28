import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  user,
  moderator,
  admin,
}

enum MembershipStatus {
  pending,
  approved,
  rejected,
  member,
}

enum Campus {
  main,
  salcedo,
  sanJuan,
  hinunangan,
  hinundayan,
  saintBernard,
  sanMiguel,
  liloan,
  sanFrancisco,
  sanRicardo,
  anahawan,
  silago,
  santaRita,
  macrohon,
  malitbog,
  tomasOppus,
  limasawa,
  padreBurgos,
}

enum Department {
  // College of Arts and Sciences
  cas,
  // College of Business and Entrepreneurship
  cbe,
  // College of Education
  coe,
  // College of Engineering
  coeng,
  // College of Technology
  cot,
  // College of Agriculture
  coa,
  // College of Fisheries
  cof,
  // College of Forestry and Environmental Science
  cofes,
  // College of Medicine
  com,
  // College of Nursing
  con,
  // College of Pharmacy
  coph,
  // Graduate School
  gs,
}

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? profileImageUrl;
  final UserRole role;
  final List<ClubMembership> clubMemberships;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isProfileComplete;
  final String? studentId;
  final String? course;
  final String? yearLevel;
  final Campus? campus;
  final Department? department;
  final List<String> notificationPreferences;
  final List<String> savedEvents;
  final List<String> savedAnnouncements;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.profileImageUrl,
    this.role = UserRole.user,
    this.clubMemberships = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isProfileComplete = false,
    this.studentId,
    this.course,
    this.yearLevel,
    this.campus,
    this.department,
    this.notificationPreferences = const [],
    this.savedEvents = const [],
    this.savedAnnouncements = const [],
  });

  String get fullName => middleName != null && middleName!.isNotEmpty 
      ? '$firstName $middleName $lastName' 
      : '$firstName $lastName';
  String get displayName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator || role == UserRole.admin;
  bool get isRegularUser => role == UserRole.user;

  // Department and campus helpers
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
      case Department.gs:
        return 'Graduate School';
      default:
        return 'Not specified';
    }
  }

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

  // Check if user is a member of a specific club
  bool isMemberOf(String clubId) {
    return clubMemberships.any((membership) => 
      membership.clubId == clubId && 
      membership.status == MembershipStatus.member
    );
  }

  // Check if user is a moderator of a specific club
  bool isModeratorOf(String clubId) {
    return clubMemberships.any((membership) => 
      membership.clubId == clubId && 
      membership.role == UserRole.moderator
    );
  }

  // Check if user can moderate a specific club
  bool canModerate(String clubId) {
    return isAdmin || isModeratorOf(clubId);
  }

  // Check if user can approve applications
  bool canApproveApplications(String clubId) {
    return isAdmin || isModeratorOf(clubId);
  }

  // Check if user can create events
  bool canCreateEvents(String clubId) {
    return isAdmin || isModeratorOf(clubId);
  }

  // Check if user can create announcements
  bool canCreateAnnouncements(String clubId) {
    return isAdmin || isModeratorOf(clubId);
  }

  // Check if user can manage club settings
  bool canManageClubSettings(String clubId) {
    return isAdmin || isModeratorOf(clubId);
  }

  // Check if user can approve public content (admin only)
  bool canApprovePublicContent() {
    return isAdmin;
  }

  // Check if user can view all departments (admin only)
  bool canViewAllDepartments() {
    return isAdmin;
  }

  // Get pending applications for clubs user moderates
  List<ClubMembership> getPendingApplications() {
    return clubMemberships.where((membership) => 
      membership.status == MembershipStatus.pending
    ).toList();
  }

  // Get clubs user moderates
  List<String> getModeratedClubIds() {
    return clubMemberships
      .where((membership) => membership.role == UserRole.moderator)
      .map((membership) => membership.clubId)
      .toList();
  }

  // Get all club IDs user is a member of
  List<String> getMemberClubIds() {
    return clubMemberships
      .where((membership) => membership.status == MembershipStatus.member)
      .map((membership) => membership.clubId)
      .toList();
  }

  // Get clubs from user's department
  List<String> getDepartmentClubIds() {
    if (department == null) return [];
    return clubMemberships
      .where((membership) => membership.status == MembershipStatus.member)
      .map((membership) => membership.clubId)
      .toList();
  }

  ClubMembership? getClubMembership(String clubId) {
    try {
      return clubMemberships.firstWhere((m) => m.clubId == clubId);
    } catch (e) {
      return null; // Return null if no membership is found
    }
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      middleName: data['middleName'],
      profileImageUrl: data['profileImageUrl'],
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${data['role'] ?? 'user'}',
        orElse: () => UserRole.user,
      ),
      clubMemberships: (data['clubMemberships'] as List<dynamic>?)
          ?.map((membership) => ClubMembership.fromMap(membership))
          .toList() ?? [],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      isProfileComplete: data['isProfileComplete'] ?? false,
      studentId: data['studentId'],
      course: data['course'],
      yearLevel: data['yearLevel'],
      campus: data['campus'] != null 
          ? Campus.values.firstWhere(
              (campus) => campus.toString() == 'Campus.${data['campus']}',
              orElse: () => Campus.main,
            )
          : null,
      department: data['department'] != null 
          ? Department.values.firstWhere(
              (dept) => dept.toString() == 'Department.${data['department']}',
              orElse: () => Department.cas,
            )
          : null,
      notificationPreferences: List<String>.from(data['notificationPreferences'] ?? []),
      savedEvents: List<String>.from(data['savedEvents'] ?? []),
      savedAnnouncements: List<String>.from(data['savedAnnouncements'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'profileImageUrl': profileImageUrl,
      'role': role.toString().split('.').last,
      'clubMemberships': clubMemberships.map((membership) => membership.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isProfileComplete': isProfileComplete,
      'studentId': studentId,
      'course': course,
      'yearLevel': yearLevel,
      'campus': campus?.toString().split('.').last,
      'department': department?.toString().split('.').last,
      'notificationPreferences': notificationPreferences,
      'savedEvents': savedEvents,
      'savedAnnouncements': savedAnnouncements,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? middleName,
    String? profileImageUrl,
    UserRole? role,
    List<ClubMembership>? clubMemberships,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isProfileComplete,
    String? studentId,
    String? course,
    String? yearLevel,
    Campus? campus,
    Department? department,
    List<String>? notificationPreferences,
    List<String>? savedEvents,
    List<String>? savedAnnouncements,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      clubMemberships: clubMemberships ?? this.clubMemberships,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      studentId: studentId ?? this.studentId,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      campus: campus ?? this.campus,
      department: department ?? this.department,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      savedEvents: savedEvents ?? this.savedEvents,
      savedAnnouncements: savedAnnouncements ?? this.savedAnnouncements,
    );
  }
}

class ClubMembership {
  final String clubId;
  final String clubName;
  final UserRole role;
  final MembershipStatus status;
  final DateTime joinedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? applicationMessage;

  ClubMembership({
    required this.clubId,
    required this.clubName,
    this.role = UserRole.user,
    this.status = MembershipStatus.pending,
    required this.joinedAt,
    this.approvedAt,
    this.approvedBy,
    this.applicationMessage,
  });

  bool get isPending => status == MembershipStatus.pending;
  bool get isApproved => status == MembershipStatus.approved;
  bool get isRejected => status == MembershipStatus.rejected;
  bool get isMember => status == MembershipStatus.member;
  bool get isModerator => role == UserRole.moderator;

  factory ClubMembership.fromMap(Map<String, dynamic> map) {
    return ClubMembership(
      clubId: map['clubId'] ?? '',
      clubName: map['clubName'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${map['role'] ?? 'user'}',
        orElse: () => UserRole.user,
      ),
      status: MembershipStatus.values.firstWhere(
        (status) => status.toString() == 'MembershipStatus.${map['status'] ?? 'pending'}',
        orElse: () => MembershipStatus.pending,
      ),
      joinedAt: map['joinedAt'] != null 
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      approvedAt: map['approvedAt'] != null ? (map['approvedAt'] as Timestamp).toDate() : null,
      approvedBy: map['approvedBy'],
      applicationMessage: map['applicationMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clubId': clubId,
      'clubName': clubName,
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'applicationMessage': applicationMessage,
    };
  }

  ClubMembership copyWith({
    String? clubId,
    String? clubName,
    UserRole? role,
    MembershipStatus? status,
    DateTime? joinedAt,
    DateTime? approvedAt,
    String? approvedBy,
    String? applicationMessage,
  }) {
    return ClubMembership(
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      applicationMessage: applicationMessage ?? this.applicationMessage,
    );
  }
} 