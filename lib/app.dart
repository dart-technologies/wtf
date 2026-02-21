import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart' show kDemoMode;
import 'screens/component_gallery.dart';
import 'screens/trip_screen.dart';
import 'theme/app_theme.dart';

class WtfApp extends ConsumerWidget {
  const WtfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Where To Flock',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      // In demo mode, start with the component gallery for quick visual testing.
      // Toggle kComponentGallery to false to go straight to the trip screen.
      home: kComponentGallery
          ? const ComponentGallery()
          : const TripScreen(tripId: 'demo-trip'),
    );
  }
}

/// Set to true to launch the component gallery instead of the trip screen.
const bool kComponentGallery = false;

