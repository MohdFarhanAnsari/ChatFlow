import 'package:flutter/material.dart';

/// Design system color palette for ChatFlow.
/// Premium fintech-grade aesthetic with deep navy surfaces and emerald accents.
class AppColors {
  AppColors._();

  // Emerald Primary Accents
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryContainer = Color(0xFF064E3B);
  static const Color onPrimary = Colors.white;

  // Dark Theme Palette (Deep Navy / Midnight)
  static const Color darkBackground = Color(0xFF0B101B);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceCard = Color(0xFF1E293B);
  static const Color darkSurfaceInput = Color(0xFF162032);
  static const Color darkBorder = Color(0xFF2B394E);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F5F9);
  static const Color lightSurfaceInput = Color(0xFFEDF2F7);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Message Bubbles
  static const Color senderBubble = Color(0xFF059669);
  static const Color senderBubbleGradientEnd = Color(0xFF10B981);
  static const Color senderBubbleDarkStart = Color(0xFF065F46);
  static const Color senderBubbleDarkEnd = Color(0xFF047857);
  static const Color receiverBubbleDark = Color(0xFF162032);
  static const Color receiverBubbleLight = Color(0xFFFFFFFF);

  // Chat Wallpaper / Canvas
  static const Color chatBackgroundDark = Color(0xFF0A0F1D);
  static const Color chatBackgroundLight = Color(0xFFF0F4F8);

  // Status & Badges
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF64748B);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color readCheck = Color(0xFF34D399);
  static const Color sentCheck = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient senderBubbleGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF0A0F1D), Color(0xFF131C2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
