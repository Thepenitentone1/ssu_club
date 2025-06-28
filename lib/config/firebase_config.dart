import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  static String get apiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get authDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get projectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get storageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get messagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get appId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  static Map<String, dynamic> get config => {
    'apiKey': apiKey,
    'authDomain': authDomain,
    'projectId': projectId,
    'storageBucket': storageBucket,
    'messagingSenderId': messagingSenderId,
    'appId': appId,
  };
} 