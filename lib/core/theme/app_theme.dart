import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Brand ─────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF059669); // brand-400 emerald
  static const Color darkGreen = Color(0xFF047857);    // brand-500
  static const Color accentAmber = Color(0xFFFFB800);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);

  // ── Neon accent colours (for stat cards, badges, highlights) ──
  static const Color neonGreen = Color(0xFF059669);   // same as brand
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonPurple = Color(0xFFBF00FF);

  // ── Dark surface palette ───────────────────────────────
  /// Used everywhere as Scaffold / page background
  static const Color backgroundGrey = Color(0xFF050505);
  /// Card surface
  static const Color cardDark = Color(0xFF0D0D0D);
  /// Modal / elevated surface
  static const Color surfaceAlt = Color(0xFF111218);
  /// Input fill
  static const Color inputDark = Color(0xFF151515);
  /// Subtle border  (slate-800)
  static const Color borderDark = Color(0xFF1E293B);

  // ── Text colours (designed for dark backgrounds) ──────
  /// Primary text — slate-200, clearly readable on dark
  static const Color textDark = Color(0xFFE2E8F0);
  /// Secondary / muted text — slate-400
  static const Color textGrey = Color(0xFF94A3B8);
  /// Subtle label text — slate-500
  static const Color textSubtle = Color(0xFF64748B);

  // ─────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const textDarkL = Color(0xFF1A1A2E);
    const textGreyL = Color(0xFF757575);
    const bgL = Color(0xFFF4F6F9);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: accentAmber,
        surface: Colors.white,
        error: errorRed,
      ),
      scaffoldBackgroundColor: bgL,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: textGreyL),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryGreen.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12);
          }
          return const TextStyle(color: textGreyL, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen);
          }
          return const IconThemeData(color: textGreyL);
        }),
      ),
      chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
      dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E0E0), thickness: 1),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDarkL),
        bodyMedium: TextStyle(color: textDarkL),
        bodySmall: TextStyle(color: textGreyL),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // DARK THEME  — matches Football-Academy reference app
  // ─────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: primaryGreen,
        onPrimary: Colors.black,
        primaryContainer: const Color(0xFF065F46),
        onPrimaryContainer: const Color(0xFFA7F3D0),
        secondary: accentAmber,
        onSecondary: Colors.black,
        secondaryContainer: const Color(0xFF78350F),
        onSecondaryContainer: const Color(0xFFFDE68A),
        error: errorRed,
        onError: Colors.white,
        errorContainer: const Color(0xFF7F1D1D),
        onErrorContainer: const Color(0xFFFECACA),
        surface: cardDark,
        onSurface: textDark,          // slate-200 — always readable
        surfaceContainerHighest: surfaceAlt,
        onSurfaceVariant: textGrey,   // slate-400
        outline: borderDark,
        outlineVariant: const Color(0xFF0F172A),
        shadow: Colors.black,
        scrim: Colors.black87,
        inverseSurface: textDark,
        onInverseSurface: backgroundGrey,
        inversePrimary: darkGreen,
      ),
      scaffoldBackgroundColor: backgroundGrey, // #050505

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            color: textDark, fontSize: 18, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: textDark),
        actionsIconTheme: IconThemeData(color: textGrey),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        shape: Border(
            bottom: BorderSide(
                color: borderDark.withValues(alpha: 0.5), width: 1)),
      ),

      // ── Elevated button — pro-button-primary ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ).copyWith(
          // Green glow shadow on button
          shadowColor:
              WidgetStatePropertyAll(primaryGreen.withValues(alpha: 0.4)),
          elevation: const WidgetStatePropertyAll(8),
        ),
      ),

      // ── Outlined button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // ── Text button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryGreen),
      ),

      // ── Input — pro-input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderDark)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderDark)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorRed, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: textGrey),
        hintStyle: TextStyle(color: textSubtle),
        prefixIconColor: textGrey,
        suffixIconColor: textGrey,
      ),

      // ── Card — pro-card ──
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: borderDark.withValues(alpha: 0.5), width: 1),
        ),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Bottom navigation bar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardDark,
        indicatorColor: primaryGreen.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12);
          }
          return TextStyle(color: textGrey, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen);
          }
          return IconThemeData(color: textGrey);
        }),
      ),

      // ── Bottom sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceAlt,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20))),
        dragHandleColor: borderDark,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceAlt,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
            color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: textGrey, fontSize: 14),
      ),

      // ── PopupMenu ──
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderDark),
        ),
        textStyle: TextStyle(color: textDark, fontSize: 14),
      ),

      // ── ListTile ──
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: textGrey,
        textColor: textDark,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primaryGreen : textGrey),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primaryGreen.withValues(alpha: 0.3)
                : borderDark),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderDark),
        ),
        labelStyle: TextStyle(color: textDark, fontSize: 12),
        selectedColor: primaryGreen.withValues(alpha: 0.2),
        checkmarkColor: primaryGreen,
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(color: borderDark, thickness: 1),

      // ── Slider ──
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryGreen,
        thumbColor: primaryGreen,
        overlayColor: Color(0x1F059669),
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: textGrey,
        indicatorColor: primaryGreen,
        dividerColor: borderDark,
      ),

      // ── Progress indicator ──
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: primaryGreen),

      // ── Icons ──
      iconTheme: IconThemeData(color: textGrey),

      // ── Text (all body text on dark bg) ──
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textDark),
        displayMedium: TextStyle(color: textDark),
        displaySmall: TextStyle(color: textDark),
        headlineLarge: TextStyle(color: textDark),
        headlineMedium: TextStyle(color: textDark),
        headlineSmall: TextStyle(color: textDark),
        titleLarge:
            TextStyle(color: textDark, fontWeight: FontWeight.bold),
        titleMedium:
            TextStyle(color: textDark, fontWeight: FontWeight.w600),
        titleSmall:
            TextStyle(color: textDark, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
        bodySmall: TextStyle(color: textGrey),
        labelLarge:
            TextStyle(color: textDark, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: textGrey),
        labelSmall: TextStyle(color: textSubtle),
      ),
    );
  }
}
