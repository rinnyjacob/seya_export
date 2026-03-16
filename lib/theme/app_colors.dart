import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Smart Pairing
  static const Color brandGold = Color(0xFFc89c6e); // Warm gold - for accents, highlights, CTAs
  static const Color brandDark = Color(0xFF1c0c1f); // Deep dark - for backgrounds, text, depth

  // Light Theme - Gold accents on light backgrounds, Dark text
  static const Color lightPrimary = Color(0xFFc89c6e); // Gold for buttons, icons
  static const Color lightPrimaryDark = Color(0xFF1c0c1f); // Dark for contrast
  static const Color lightAccent = Color(0xFFd4a876); // Lighter gold
  static const Color lightAccentDark = Color(0xFFb08858); // Darker gold
  static const Color lightBackground = Color(0xFFFAFAFA); // Light neutral
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white cards
  static const Color lightError = Color(0xFFEF4444);
  static const Color lightText = Color(0xFF1c0c1f); // Dark text for readability
  static const Color lightTextSecondary = Color(0xFF4d3d50); // Softer dark
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFF3F4F6);
  static const Color lightCardAccent = Color(0xFF1c0c1f); // Dark cards for contrast

  // Dark Theme - Gold accents on dark backgrounds
  static const Color darkPrimary = Color(0xFFc89c6e); // Gold pops on dark
  static const Color darkPrimaryDark = Color(0xFFb08858); // Darker gold
  static const Color darkAccent = Color(0xFFd4a876); // Lighter gold for highlights
  static const Color darkAccentDark = Color(0xFFc89c6e); // Base gold
  static const Color darkBackground = Color(0xFF1c0c1f); // Deep dark base
  static const Color darkSurface = Color(0xFF2a1a2d); // Slightly lighter dark for cards
  static const Color darkSurfaceSecondary = Color(0xFF3d2d40); // More elevated surface
  static const Color darkError = Color(0xFFFCA5A5);
  static const Color darkText = Color(0xFFF1F5F9); // Light text on dark
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Softer light
  static const Color darkBorder = Color(0xFF4d3d50); // Subtle borders
  static const Color darkDivider = Color(0xFF3d2d40); // Subtle dividers
  static const Color darkCardAccent = Color(0xFFc89c6e); // Gold for special cards

  // Gradient Colors - Smart combinations
  static const List<Color> lightGradient = [
    Color(0xFFc89c6e), // Gold
    Color(0xFFd4a876), // Lighter gold
  ];

  static const List<Color> darkGradient = [
    Color(0xFFc89c6e), // Gold
    Color(0xFF1c0c1f), // Dark - creates depth
  ];

  // Premium Gradients - Gold to Dark for luxury feel
  static const List<Color> premiumGradient = [
    Color(0xFFc89c6e), // Gold start
    Color(0xFFb08858), // Mid gold
    Color(0xFF1c0c1f), // Dark end
  ];

  // Hero Gradients - Dark to Gold for headers
  static const List<Color> heroGradient = [
    Color(0xFF1c0c1f), // Dark start
    Color(0xFF2a1a2d), // Mid dark
    Color(0xFFc89c6e), // Gold end
  ];

  // Accent Gradients
  static const List<Color> accentGradient = [
    Color(0xFFd4a876), // Light gold
    Color(0xFFc89c6e), // Base gold
  ];

  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF34D399),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFCD34D),
  ];

  // Status Colors
  static const Color onlineGreen = Color(0xFF10B981);
  static const Color offlineGray = Color(0xFF9CA3AF);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color callingBlue = Color(0xFF3B82F6);

  // Transparent variants for overlays
  static const Color goldTransparent10 = Color(0x1Ac89c6e); // 10% opacity
  static const Color goldTransparent20 = Color(0x33c89c6e); // 20% opacity
  static const Color darkTransparent10 = Color(0x1A1c0c1f); // 10% opacity
  static const Color darkTransparent20 = Color(0x331c0c1f); // 20% opacity
  static const Color darkTransparent50 = Color(0x801c0c1f); // 50% opacity
  static const Color darkTransparent70 = Color(0xB31c0c1f); // 70% opacity

  // Legacy support
  static const Color lightPrimaryTransparent = goldTransparent10;
  static const Color darkPrimaryTransparent = goldTransparent10;
  static const Color accentTransparent = goldTransparent20;
}



