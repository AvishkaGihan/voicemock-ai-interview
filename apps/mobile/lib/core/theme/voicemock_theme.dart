import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark Neon-Green theme colors for VoiceMock.
///
/// A premium, dark color palette with neon green accents
/// designed for a futuristic, tech-forward interview coach.
abstract final class VoiceMockColors {
  // Primary Colors
  static const Color primary = Color(0xFF00E676); // Neon green
  static const Color secondary = Color(0xFF00BFA5); // Bright teal-green
  static const Color background = Color(0xFF0A0E14); // Near-black
  static const Color surface = Color(0xFF141A22); // Dark charcoal
  static const Color textPrimary = Color(0xFFE8ECF0); // Off-white
  static const Color textMuted = Color(0xFF7A8A9C); // Slate grey

  // New Design Tokens
  static const Color primaryContainer = Color(0xFF0D2818); // Deep green tint
  static const Color accentGlow = Color(0x1400E676); // 8% primary for shadows
  static const Color surfaceBorder = Color(0xFF1C2430); // Subtle card borders
  static const Color surfaceElevated = Color(0xFF1A2230); // Elevated surface
  static const Color gradientStart = Color(0xFF00E676); // CTA gradient start
  static const Color gradientEnd = Color(0xFF00BCD4); // CTA gradient end

  // Semantic Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5252);

  // Setup Redesign Tokens
  static const Color surfaceCard = Color(0xFF111820); // Sectioned card fill
  static const Color glowPrimary = Color(0x3300E676); // 20% primary glow

  /// Standard glassmorphic card decoration used across setup widgets.
  static BoxDecoration cardDecoration({
    Color? borderColor,
    double radius = VoiceMockRadius.lg,
  }) =>
      BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? surfaceBorder),
      );

  /// Elevated card decoration with subtle primary glow.
  ///
  /// Used for prominent cards (question card, feedback card) that need
  /// visual lift above standard cards.
  static BoxDecoration cardDecorationElevated({
    Color? borderColor,
    double radius = VoiceMockRadius.lg,
  }) =>
      BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );
}

/// Spacing constants based on 8dp grid.
abstract final class VoiceMockSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Typography styles for VoiceMock using Inter font.
abstract final class VoiceMockTypography {
  static final TextStyle h1 = GoogleFonts.inter(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w600,
    color: VoiceMockColors.textPrimary,
  );

  static final TextStyle h2 = GoogleFonts.inter(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    color: VoiceMockColors.textPrimary,
  );

  static final TextStyle h3 = GoogleFonts.inter(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: VoiceMockColors.textPrimary,
  );

  /// Sub-section header — between h3 and body.
  /// Used for secondary headings in interview screen sections.
  static final TextStyle h4 = GoogleFonts.inter(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    color: VoiceMockColors.textPrimary,
  );

  static final TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: VoiceMockColors.textPrimary,
  );

  static final TextStyle small = GoogleFonts.inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: VoiceMockColors.textMuted,
  );

  static final TextStyle micro = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: VoiceMockColors.textMuted,
  );

  static final TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: VoiceMockColors.textMuted,
  );

  /// Section header style — all-caps neon green labels
  /// like "✦ OVERALL ASSESSMENT", "✦ YOUR STRENGTHS"
  static final TextStyle sectionLabel = GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: VoiceMockColors.primary,
  );
}

/// Border radius constants.
abstract final class VoiceMockRadius {
  static const double sm = 6;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double full = 999; // Pill radius
}
