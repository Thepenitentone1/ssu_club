import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'announcements';

  // Create a new announcement
  Future<AnnouncementModel> createAnnouncement(AnnouncementModel announcement) async {
    final docRef = await _firestore.collection(_collection).add(announcement.toFirestore());
    return announcement;
  }

  // Get all announcements (excluding expired ones)
  Stream<List<AnnouncementModel>> getAnnouncements() {
    return _firestore
        .collection(_collection)
        .where('expiryDate', isGreaterThan: Timestamp.now()) // Only show non-expired announcements
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList();
    });
  }

  // Get pinned announcements (excluding expired ones)
  Stream<List<AnnouncementModel>> getPinnedAnnouncements() {
    return _firestore
        .collection(_collection)
        .where('isPinned', isEqualTo: true)
        .where('expiryDate', isGreaterThan: Timestamp.now()) // Only show non-expired announcements
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList();
    });
  }

  // Get important announcements (excluding expired ones)
  Stream<List<AnnouncementModel>> getImportantAnnouncements() {
    return _firestore
        .collection(_collection)
        .where('isImportant', isEqualTo: true)
        .where('expiryDate', isGreaterThan: Timestamp.now()) // Only show non-expired announcements
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList();
    });
  }

  // Get announcements by tag (excluding expired ones)
  Stream<List<AnnouncementModel>> getAnnouncementsByTag(String tag) {
    return _firestore
        .collection(_collection)
        .where('tags', arrayContains: tag)
        .where('expiryDate', isGreaterThan: Timestamp.now()) // Only show non-expired announcements
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList();
    });
  }

  // Get expired announcements (for admin review)
  Stream<List<AnnouncementModel>> getExpiredAnnouncements() {
    return _firestore
        .collection(_collection)
        .where('expiryDate', isLessThan: Timestamp.now())
        .orderBy('expiryDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList();
    });
  }

  // Update an announcement
  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete an announcement (direct deletion for admins)
  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Request deletion (for moderators - requires admin approval)
  Future<void> requestAnnouncementDeletion(String announcementId, String requesterId, String reason) async {
    await _firestore.collection('deletionRequests').add({
      'type': 'announcement',
      'itemId': announcementId,
      'requesterId': requesterId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Auto-remove expired announcements (called by Cloud Functions or scheduled task)
  Future<void> removeExpiredAnnouncements() async {
    final now = Timestamp.now();
    final expiredAnnouncements = await _firestore
        .collection(_collection)
        .where('expiryDate', isLessThan: now)
        .get();

    for (final doc in expiredAnnouncements.docs) {
      await doc.reference.delete();
    }
  }

  // Toggle pin status
  Future<void> togglePinStatus(String id, bool isPinned) async {
    await _firestore.collection(_collection).doc(id).update({
      'isPinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Toggle important status
  Future<void> toggleImportantStatus(String id, bool isImportant) async {
    await _firestore.collection(_collection).doc(id).update({
      'isImportant': isImportant,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get pending public announcements (for admin approval)
  Stream<List<AnnouncementModel>> getPendingAnnouncements() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList();
    });
  }

  // Get pending announcements for a specific club (for moderator approval)
  Stream<List<AnnouncementModel>> getPendingAnnouncementsByClub(String clubId) {
    return _firestore
        .collection(_collection)
        .where('clubId', isEqualTo: clubId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList();
    });
  }

  // Get deletion requests (for admin review)
  Stream<List<Map<String, dynamic>>> getDeletionRequests() {
    return _firestore
        .collection('deletionRequests')
        .where('type', isEqualTo: 'announcement')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  // Approve deletion request (admin only)
  Future<void> approveDeletionRequest(String requestId) async {
    final request = await _firestore.collection('deletionRequests').doc(requestId).get();
    if (request.exists) {
      final data = request.data()!;
      final announcementId = data['itemId'] as String;
      
      // Delete the announcement
      await deleteAnnouncement(announcementId);
      
      // Update the request status
      await _firestore.collection('deletionRequests').doc(requestId).update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Reject deletion request (admin only)
  Future<void> rejectDeletionRequest(String requestId, String reason) async {
    await _firestore.collection('deletionRequests').doc(requestId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
} 