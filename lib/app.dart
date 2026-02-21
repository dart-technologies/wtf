import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // TODO(mike): wire up proper routing (go_router) when multi-trip nav is needed
      home: const TripScreen(tripId: 'demo-trip'),
    );
  }
}
