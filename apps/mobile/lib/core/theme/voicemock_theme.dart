import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Calm Ocean theme colors for VoiceMock.
///
/// A calming, professional color palette designed to reduce interview anxiety.
abstract final class VoiceMockColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563EB); // Deeper, cooler blue
  static const Color secondary = Color(0xFF27B39B);
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF5B6475);

  // New Design Tokens
  static const Color primaryContainer = Color(0xFFEEF3FE); // Tinted wash
  static const Color accentGlow = Color(0x1A2563EB); // 10% primary for shadows

  // Semantic Colors
  static const Color success = Color(0xFF1E9E6A);
  static const Color warning = Color(0xFFD99A00);
  static const Color error = Color(0xFFD64545);
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
}

/// Border radius constants.
abstract final class VoiceMockRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 999; // Pill radius
}
