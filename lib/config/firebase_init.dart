import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseInit {
  static Future<void> initialize() async {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyADVvdHg_bqMiB6b0SuXCvE3IsNnFJ6PNo",
          authDomain: "club-3835e.firebaseapp.com",
          projectId: "club-3835e",
          storageBucket: "club-3835e.firebasestorage.app",
          messagingSenderId: "598271554302",
          appId: "1:598271554302:web:872ab44150b04b0c0c2baf",
        ),
      );
    } else {
      try {
        print('Current directory: \\${Directory.current.path}');
        print('.env file exists: \\${File('.env').existsSync()}');
        if (File('.env').existsSync()) {
          final bytes = File('.env').readAsBytesSync();
          print('First 20 bytes of .env: \\${bytes.take(20).toList()}');
          final content = File('.env').readAsStringSync();
          print('First 200 chars of .env: \\${content.substring(0, content.length > 200 ? 200 : content.length)}');
        }
        await dotenv.load();
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: FirebaseConfig.apiKey,
            authDomain: FirebaseConfig.authDomain,
            projectId: FirebaseConfig.projectId,
            storageBucket: FirebaseConfig.storageBucket,
            messagingSenderId: FirebaseConfig.messagingSenderId,
            appId: FirebaseConfig.appId,
          ),
        );
        print('Firebase initialized successfully');
      } catch (e) {
        print('Error initializing Firebase: $e');
        rethrow;
      }
    }
  }
} 