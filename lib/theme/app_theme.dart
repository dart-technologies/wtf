import 'package:flutter/material.dart';

class AppColors {
  // ── Person palette (vibrant on dark) ──────────────────────────────────────
  static const personA = Color(0xFF58A6FF); // Abby — sky blue
  static const personB = Color(0xFFFF7B7B); // Mike — coral

  // ── Block status ───────────────────────────────────────────────────────────
  static const unclaimed = Color(0xFF6E7681);
  static const decided = Color(0xFF3FB950); // green
  static const ai = Color(0xFFD2A8FF); // soft purple

  // ── Dark mode surfaces ─────────────────────────────────────────────────────
  static const background = Color(0xFF0D1117); // GitHub dark bg
  static const surface = Color(0xFF161B22);    // card bg
  static const elevated = Color(0xFF1C2128);   // elevated card / sidebar bg
  static const divider = Color(0xFF30363D);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Color forPersonId(String personId) => switch (personId) {
        'person_a' => personA,
        'person_b' => personB,
        'ai' => ai,
        _ => unclaimed,
      };

  /// Real GitHub avatar URLs keyed by person_id.
  static String? avatarUrl(String personId) => switch (personId) {
        'person_a' => 'https://avatars.githubusercontent.com/u/226324761?v=4',
        'person_b' => 'https://avatars.githubusercontent.com/u/1755207?v=4',
        _ => null,
      };
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.personA,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.divider),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.divider),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.personA,
            foregroundColor: Colors.black,
          ),
        ),
      );
}

/// A [CircleAvatar] that shows the real GitHub photo for known person IDs
/// and falls back to the initial letter for unknowns / network errors.
class PersonAvatar extends StatelessWidget {
  final String personId;
  final String name;
  final double radius;

  const PersonAvatar({
    super.key,
    required this.personId,
    required this.name,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forPersonId(personId);
    final url = AppColors.avatarUrl(personId);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Text(
              name[0].toUpperCase(),
              style: TextStyle(
                fontSize: radius * 0.85,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
