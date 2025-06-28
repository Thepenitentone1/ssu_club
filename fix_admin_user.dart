import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  await Firebase.initializeApp();

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  const adminEmail = 'edward@gmail.com';
  const adminPassword = 'admin123';

  UserCredential? userCredential;

  // Try to sign in, or create the user if not exists
  try {
    userCredential = await auth.signInWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );
    print('Signed in as $adminEmail');
  } catch (e) {
    print('User not found, creating...');
    userCredential = await auth.createUserWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );
    print('Created user $adminEmail');
  }

  final user = userCredential.user;
  if (user == null) {
    print('Failed to get user');
    return;
  }

  // Update Firestore user document
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
  }, SetOptions(merge: true));

  print('User $adminEmail is now an admin!');
} 