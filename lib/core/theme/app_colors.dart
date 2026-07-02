import 'package:flutter/material.dart';

class AppColors {
  // ── Background & Surface ──────────────────────────────────────────────────
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF253347);
  static const Color cardBorder = Color(0xFF334155);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED); // Purple Neon
  static const Color primaryLight = Color(0xFF9D5FF0);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color accent = Color(0xFFA3FF12); // Neon Green
  static const Color accentDark = Color(0xFF7ACC0D);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF475569);

  // ── Glow / Neon Effects ───────────────────────────────────────────────────
  static const Color glowPurple = Color(0x407C3AED);
  static const Color glowGreen = Color(0x40A3FF12);
  static const Color glowDanger = Color(0x40EF4444);
  static const Color glowSuccess = Color(0x4022C55E);
  static const Color glowWarning = Color(0x40F59E0B);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFA3FF12), Color(0xFF7ACC0D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1A1035)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF162032)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Status Colors (for PS/PC status) ─────────────────────────────────────
  static const Color statusAvailable = Color(0xFF22C55E);
  static const Color statusPlaying = Color(0xFF7C3AED);
  static const Color statusReserved = Color(0xFFF59E0B);
  static const Color statusMaintain = Color(0xFFEF4444);

  // ── Glassmorphism ─────────────────────────────────────────────────────────
  static Color glassWhite = Colors.white.withOpacity(0.05);
  static Color glassBorder = Colors.white.withOpacity(0.10);
  static Color glassOverlay = Colors.white.withOpacity(0.03);
}
