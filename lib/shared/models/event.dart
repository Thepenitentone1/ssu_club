import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart'; // Assuming Department and Campus enums are defined here or elsewhere

// Enum for event types
enum EventType {
  academic,
  cultural,
  sports,
  social,
  professional,
  religious,
  environmental,
  health,
  technical,
  other,
}

// Enum for event visibility
enum EventVisibility {
  public,
  private,
  department,
  club,
}

// Enum for event status
enum EventStatus {
  draft,
  pending,
  approved,
  rejected,
  active,
  cancelled,
  completed,
}

enum Campus { main, satellite }

class EventModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? location;
  final DateTime startDate;
  final DateTime endDate;
  final EventType type;
  final EventVisibility visibility;
  final EventStatus status;
  final String clubId;
  final String clubName;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final List<String> attendeeIds;
  final List<String> rsvpIds;
  final int maxAttendees;
  final bool requiresRSVP;
  final bool isFree;
  final double? fee;
  final String? contactEmail;
  final String? contactPhone;
  final String? externalLink;
  final Department? department; // Assuming Department enum is defined elsewhere
  final Campus? campus;         // Assuming Campus enum is defined elsewhere
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final Map<String, dynamic> metadata;

  // Constructor with required and optional parameters
  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.location,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.visibility = EventVisibility.club,
    this.status = EventStatus.draft,
    required this.clubId,
    required this.clubName,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.attendeeIds = const [],
    this.rsvpIds = const [],
    this.maxAttendees = 0,
    this.requiresRSVP = false,
    this.isFree = true,
    this.fee,
    this.contactEmail,
    this.contactPhone,
    this.externalLink,
    this.department,
    this.campus,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.metadata = const {},
  });

  // Factory constructor to create an EventModel from Firestore data
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      location: data['location'],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: EventType.values.firstWhere(
        (type) => type.toString() == 'EventType.${data['type']}',
        orElse: () => EventType.other,
      ),
      visibility: EventVisibility.values.firstWhere(
        (vis) => vis.toString() == 'EventVisibility.${data['visibility']}',
        orElse: () => EventVisibility.club,
      ),
      status: EventStatus.values.firstWhere(
        (stat) => stat.toString() == 'EventStatus.${data['status']}',
        orElse: () => EventStatus.draft,
      ),
      clubId: data['clubId'] ?? '',
      clubName: data['clubName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      attendeeIds: List<String>.from(data['attendeeIds'] ?? []),
      rsvpIds: List<String>.from(data['rsvpIds'] ?? []),
      maxAttendees: data['maxAttendees'] ?? 0,
      requiresRSVP: data['requiresRSVP'] ?? false,
      isFree: data['isFree'] ?? true,
      fee: data['fee']?.toDouble(),
      contactEmail: data['contactEmail'],
      contactPhone: data['contactPhone'],
      externalLink: data['externalLink'],
      department: data['department'] != null
          ? Department.values.firstWhere(
              (dept) => dept.toString() == 'Department.${data['department']}',
              orElse: () => Department.cas, // Default department, adjust as needed
            )
          : null,
      campus: data['campus'] != null
          ? Campus.values.firstWhere(
              (camp) => camp.toString() == 'Campus.${data['campus']}',
              orElse: () => Campus.main, // Default campus, adjust as needed
            )
          : null,
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Method to convert EventModel to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'type': type.toString().split('.').last,
      'visibility': visibility.toString().split('.').last,
      'status': status.toString().split('.').last,
      'clubId': clubId,
      'clubName': clubName,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'attendeeIds': attendeeIds,
      'rsvpIds': rsvpIds,
      'maxAttendees': maxAttendees,
      'requiresRSVP': requiresRSVP,
      'isFree': isFree,
      'fee': fee,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'externalLink': externalLink,
      'department': department?.toString().split('.').last,
      'campus': campus?.toString().split('.').last,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'metadata': metadata,
    };
  }

  // CopyWith method to create a new instance with updated fields
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    EventVisibility? visibility,
    EventStatus? status,
    String? clubId,
    String? clubName,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    List<String>? attendeeIds,
    List<String>? rsvpIds,
    int? maxAttendees,
    bool? requiresRSVP,
    bool? isFree,
    double? fee,
    String? contactEmail,
    String? contactPhone,
    String? externalLink,
    Department? department,
    Campus? campus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      rsvpIds: rsvpIds ?? this.rsvpIds,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      requiresRSVP: requiresRSVP ?? this.requiresRSVP,
      isFree: isFree ?? this.isFree,
      fee: fee ?? this.fee,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      externalLink: externalLink ?? this.externalLink,
      department: department ?? this.department,
      campus: campus ?? this.campus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to check if a user can view the event
  bool canBeViewedBy(UserModel user) {
    if (visibility == EventVisibility.public && status == EventStatus.approved) {
      return true;
    }
    if (user.isAdmin) return true;
    if (visibility == EventVisibility.department &&
        department == user.department) {
      return true;
    }
    if (visibility == EventVisibility.club && user.isMemberOf(clubId)) {
      return true;
    }
    if (createdBy == user.id) return true;
    return false;
  }

  // Helper method to check if a user can edit the event
  bool canBeEditedBy(UserModel user) {
    if (user.isAdmin) return true;
    if (createdBy == user.id && status != EventStatus.completed) return true;
    return false;
  }

  // Helper method to check if a user can approve the event
  bool canBeApprovedBy(UserModel user) {
    if (user.isAdmin && status == EventStatus.pending) return true;
    return false;
  }

  // Getter for department name
  String get departmentName {
    switch (department) {
      case Department.cas:
        return 'College of Arts and Sciences';
      case Department.coeng:
        return 'College of Engineering';
      // Add other cases as needed
      default:
        return 'Not specified';
    }
  }

  // Getter for campus name
  String get campusName {
    switch (campus) {
      case Campus.main:
        return 'Main Campus';
      // case Campus.satellite:
      //   return 'Satellite Campus';
      // Add other cases as needed
      default:
        return 'Not specified';
    }
  }

  // Getter to check if event is upcoming
  bool get isUpcoming {
    return startDate.isAfter(DateTime.now());
  }

  // Getter for attendee count
  int get attendeeCount {
    return attendeeIds.length;
  }

  // Getter for event type name
  String get typeName {
    switch (type) {
      case EventType.academic:
        return 'Academic';
      case EventType.cultural:
        return 'Cultural';
      case EventType.sports:
        return 'Sports';
      case EventType.social:
        return 'Social';
      case EventType.professional:
        return 'Professional';
      case EventType.religious:
        return 'Religious';
      case EventType.environmental:
        return 'Environmental';
      case EventType.health:
        return 'Health';
      case EventType.technical:
        return 'Technical';
      case EventType.other:
        return 'Other';
    }
  }

  // Getter to check if user can RSVP
  bool get canRSVP {
    return status == EventStatus.approved && 
           startDate.isAfter(DateTime.now()) && 
           (maxAttendees == 0 || attendeeCount < maxAttendees);
  }

  // Getter for status name
  String get statusName {
    switch (status) {
      case EventStatus.draft:
        return 'Draft';
      case EventStatus.pending:
        return 'Pending';
      case EventStatus.approved:
        return 'Approved';
      case EventStatus.rejected:
        return 'Rejected';
      case EventStatus.active:
        return 'Active';
      case EventStatus.cancelled:
        return 'Cancelled';
      case EventStatus.completed:
        return 'Completed';
    }
  }
}

// Note: Department and Campus enums are not defined here.
// They are assumed to be defined in 'user.dart' or another file.
// Example definitions might be:
// enum Department { cas, engineering, business, ... }
// enum Campus { main, satellite, ... }