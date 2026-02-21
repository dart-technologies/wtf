import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Person palette
  static const personA = Color(0xFFE54F9B); // Abby — magenta pink
  static const personB = Color(0xFF4A6CF7); // Mike — deep blue

  // Block status
  static const unclaimed = Color(0xFF5A5A64); // dark grey
  static const decided = Color(0xFF985DC9); // royal purple

  // AI-owned
  static const ai = Color(0xFF985DC9); // purple (matches aligned)

  // Surface
  static const background = Color(0xFF1E1E24); // warm charcoal
  static const surface = Color(0xFF2A2A32); // elevated surface
  static const surfaceElevated = Color(0xFF33333C); // extra lift for cards
  static const elevated = surfaceElevated; // alias used by layout widgets
  static const divider = Color(0xFF3A3A44); // subtle dark separator

  // Text
  static const textPrimary = Color(0xFFEDEDED); // off-white
  static const textSecondary = Color(0xFF8A8A96); // muted

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
  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.personA,
        brightness: Brightness.dark,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.personA,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
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
