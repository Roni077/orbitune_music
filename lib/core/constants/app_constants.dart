import 'package:flutter/material.dart';

/// Dimensions, animation durations, and standard radius tokens
class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'Orbitune';
  static const String appVersion = '1.0.0';

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration standardAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 400);
  static const Duration discRotationDuration = Duration(seconds: 20);

  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusExtraLarge = 32.0;

  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius roundedPill = BorderRadius.all(Radius.circular(999.0));

  // Layout Dimensions
  static const double miniPlayerHeight = 68.0;
  static const double bottomNavHeight = 72.0;
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 16.0;

  // Blur Tokens
  static const double glassBlurSigma = 16.0;
}
