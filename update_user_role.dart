import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// This script can be used to manually update a user's role to admin
// Run this if you need to make an existing user an admin

Future<void> updateUserToAdmin(String userEmail) async {
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;

  try {
    // Find user by email
    final usersQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .get();

    if (usersQuery.docs.isEmpty) {
      print('User with email $userEmail not found');
      return;
    }

    final userDoc = usersQuery.docs.first;
    final userId = userDoc.id;

    // Update user role to admin
    await firestore.collection('users').doc(userId).update({
      'role': 'admin',
      'updatedAt': Timestamp.now(),
    });

    print('Successfully updated $userEmail to admin role');
  } catch (e) {
    print('Error updating user role: $e');
  }
}

// Example usage:
// updateUserToAdmin('edward@gmail.com'); 