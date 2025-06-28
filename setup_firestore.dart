import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// This script sets up the initial Firestore structure
// Run this once to create the admin user and initial data

Future<void> setupFirestore() async {
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  try {
    // Create admin user account if it doesn't exist
    final adminEmail = 'edward@gmail.com';
    final adminPassword = 'admin123'; // Updated password
    
    // Check if admin user exists
    try {
      await auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);
      print('Admin user already exists and signed in');
    } catch (e) {
      // Create admin user
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      
      print('Admin user created successfully');
    }

    // Get the current user (should be edward@gmail.com now)
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      print('No user is signed in');
      return;
    }

    // Update or create admin user document with admin role
    await firestore.collection('users').doc(currentUser.uid).set({
      'id': currentUser.uid,
      'email': adminEmail,
      'firstName': 'Edward',
      'lastName': 'Admin',
      'role': 'admin', // Ensure admin role is set
      'clubMemberships': [],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'department': 'cas',
      'campus': 'main',
      'isActive': true,
      'isProfileComplete': true,
    }, SetOptions(merge: true));
    
    print('Admin user document updated with admin role');

    // Create sample clubs
    await _createSampleClubs(firestore);
    
    // Create sample events
    await _createSampleEvents(firestore);
    
    // Create sample announcements
    await _createSampleAnnouncements(firestore);
    
    print('Firestore setup completed successfully!');
    print('Admin credentials:');
    print('Email: $adminEmail');
    print('Password: $adminPassword');
    
  } catch (e) {
    print('Error setting up Firestore: $e');
  }
}

Future<void> _createSampleClubs(FirebaseFirestore firestore) async {
  final clubs = [
    {
      'name': 'Computer Science Society',
      'description': 'A community for computer science enthusiasts',
      'category': 'Academic',
      'department': 'cas',
      'campus': 'main',
      'moderatorIds': [],
      'memberCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'isActive': true,
      'imageUrl': 'https://via.placeholder.com/400x200/3B82F6/FFFFFF?text=CS+Society',
    },
    {
      'name': 'Student Government',
      'description': 'Representing student interests and organizing events',
      'category': 'Leadership',
      'department': 'cas',
      'campus': 'main',
      'moderatorIds': [],
      'memberCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'isActive': true,
      'imageUrl': 'https://via.placeholder.com/400x200/1E3A8A/FFFFFF?text=Student+Gov',
    },
  ];

  for (final club in clubs) {
    await firestore.collection('clubs').add(club);
  }
  
  print('Sample clubs created');
}

Future<void> _createSampleEvents(FirebaseFirestore firestore) async {
  final events = [
    {
      'title': 'Welcome Week 2024',
      'description': 'Join us for a week of fun activities to welcome new students',
      'location': 'Main Campus',
      'type': 'cultural',
      'startDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30, hours: 6))),
      'clubId': 'admin',
      'clubName': 'SSU Administration',
      'createdBy': 'admin',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'tags': ['Student Life', 'Events'],
      'visibility': 'public',
      'status': 'approved',
      'attendeeIds': [],
      'rsvpIds': [],
      'maxAttendees': 0,
      'requiresRSVP': false,
      'isFree': true,
      'imageUrl': 'https://via.placeholder.com/400x200/3B82F6/FFFFFF?text=Welcome+Week',
    },
  ];

  for (final event in events) {
    await firestore.collection('events').add(event);
  }
  
  print('Sample events created');
}

Future<void> _createSampleAnnouncements(FirebaseFirestore firestore) async {
  final announcements = [
    {
      'title': 'Welcome to SSU Club Hub',
      'content': 'Welcome to the new SSU Club Hub platform! Explore clubs, events, and announcements.',
      'type': 'general',
      'clubId': 'admin',
      'clubName': 'SSU Administration',
      'createdBy': 'admin',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'tags': ['Important'],
      'isPinned': true,
      'isImportant': true,
      'visibility': 'public',
      'status': 'approved',
      'readByIds': [],
      'importantForIds': [],
      'imageUrl': 'https://via.placeholder.com/400x200/3B82F6/FFFFFF?text=Welcome',
    },
  ];

  for (final announcement in announcements) {
    await firestore.collection('announcements').add(announcement);
  }
  
  print('Sample announcements created');
}

// Run this function to set up Firestore
void main() async {
  await setupFirestore();
} 