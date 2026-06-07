import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/firebase_init_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitService.initialize();
  runApp(
    const ProviderScope(
      child: OrthoClinicApp(),
    ),
  );
}
