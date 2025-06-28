import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Simple function to fix admin user - can be called from main app
Future<void> fixAdminUser() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  const adminEmail = 'edward@gmail.com';
  const adminPassword = 'admin123';

  try {
    // Try to sign in
    await auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);
    print('Signed in as $adminEmail');
  } catch (e) {
    print('Creating admin user...');
    // Create user if doesn't exist
    await auth.createUserWithEmailAndPassword(email: adminEmail, password: adminPassword);
    print('Created admin user $adminEmail');
  }

  final user = auth.currentUser;
  if (user == null) {
    print('Failed to get user');
    return;
  }

  // Update Firestore document with admin role
  await firestore.collection('users').doc(user.uid).set({
    'id': user.uid,
    'email': adminEmail,
    'firstName': 'Edward',
    'lastName': 'Admin',
    'role': 'admin',
    'clubMemberships': [],
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
    'department': 'cas',
    'campus': 'main',
    'isActive': true,
    'isProfileComplete': true,
  }, SetOptions(merge: true));

  print('✅ Admin user fixed!');
  print('Email: $adminEmail');
  print('Password: $adminPassword');
  print('Role: admin');
} 