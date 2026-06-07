import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

/// Bootstraps Firebase and enables offline persistence per platform.
class FirebaseInitService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _configureFirestorePersistence();
  }

  static Future<void> _configureFirestorePersistence() async {
    final firestore = FirebaseFirestore.instance;

    // Offline cache: IndexedDB (web), SQLite (mobile/desktop).
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // 100 MB bounded cache
    );

  }
}
