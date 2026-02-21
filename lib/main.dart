import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

// Set to true to skip Firebase and render with mock data locally.
const bool kDemoMode = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDemoMode) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'REPLACE_ME',
        appId: 'REPLACE_ME',
        messagingSenderId: 'REPLACE_ME',
        projectId: 'REPLACE_ME',
      ),
    );
  }
  runApp(const ProviderScope(child: WtfApp()));
}
