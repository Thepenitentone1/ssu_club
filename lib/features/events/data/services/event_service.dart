import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Create a new event
  Future<EventModel> createEvent(EventModel event) async {
    final docRef = await _firestore.collection(_collection).add(event.toFirestore());
    return event;
  }

  // Get all events (excluding expired ones)
  Stream<List<EventModel>> getEvents() {
    return _firestore
        .collection(_collection)
        .where('endDate', isGreaterThan: Timestamp.now()) // Only show non-expired events
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get upcoming events
  Stream<List<EventModel>> getUpcomingEvents() {
    return _firestore
        .collection(_collection)
        .where('startDate', isGreaterThan: Timestamp.now())
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get ongoing events
  Stream<List<EventModel>> getOngoingEvents() {
    final now = Timestamp.now();
    return _firestore
        .collection(_collection)
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThanOrEqualTo: now)
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get past events (for admin review)
  Stream<List<EventModel>> getPastEvents() {
    return _firestore
        .collection(_collection)
        .where('endDate', isLessThan: Timestamp.now())
        .orderBy('endDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get events by tag
  Stream<List<EventModel>> getEventsByTag(String tag) {
    return _firestore
        .collection(_collection)
        .where('tags', arrayContains: tag)
        .where('endDate', isGreaterThan: Timestamp.now()) // Only show non-expired events
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get events by organizer
  Stream<List<EventModel>> getEventsByOrganizer(String organizerId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: organizerId)
        .where('endDate', isGreaterThan: Timestamp.now()) // Only show non-expired events
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get user's registered events
  Stream<List<EventModel>> getUserRegisteredEvents(String userId) {
    return _firestore
        .collection(_collection)
        .where('attendeeIds', arrayContains: userId)
        .where('endDate', isGreaterThan: Timestamp.now()) // Only show non-expired events
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Update an event
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete an event (direct deletion for admins)
  Future<void> deleteEvent(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Request deletion (for moderators - requires admin approval)
  Future<void> requestEventDeletion(String eventId, String requesterId, String reason) async {
    await _firestore.collection('deletionRequests').add({
      'type': 'event',
      'itemId': eventId,
      'requesterId': requesterId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Auto-remove expired events (called by Cloud Functions or scheduled task)
  Future<void> removeExpiredEvents() async {
    final now = Timestamp.now();
    final expiredEvents = await _firestore
        .collection(_collection)
        .where('endDate', isLessThan: now)
        .get();

    for (final doc in expiredEvents.docs) {
      await doc.reference.delete();
    }
  }

  // Register user for an event
  Future<void> registerForEvent(String eventId, String userId) async {
    await _firestore.collection(_collection).doc(eventId).update({
      'attendeeIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Unregister user from an event
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    await _firestore.collection(_collection).doc(eventId).update({
      'attendeeIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Check if user is registered for an event
  Future<bool> isUserRegistered(String eventId, String userId) async {
    final doc = await _firestore.collection(_collection).doc(eventId).get();
    if (!doc.exists) return false;
    final event = EventModel.fromFirestore(doc);
    return event.attendeeIds.contains(userId);
  }

  // Get pending public events (for admin approval)
  Stream<List<EventModel>> getPendingEvents() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get pending events for a specific club (for moderator approval)
  Stream<List<EventModel>> getPendingEventsByClub(String clubId) {
    return _firestore
        .collection(_collection)
        .where('clubId', isEqualTo: clubId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get deletion requests (for admin review)
  Stream<List<Map<String, dynamic>>> getDeletionRequests() {
    return _firestore
        .collection('deletionRequests')
        .where('type', isEqualTo: 'event')
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
      final eventId = data['itemId'] as String;
      
      // Delete the event
      await deleteEvent(eventId);
      
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