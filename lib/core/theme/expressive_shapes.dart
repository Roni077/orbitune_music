import 'package:flutter/material.dart';

/// Material 3 Expressive Shape tokens and morphable border definitions
class ExpressiveShapes {
  ExpressiveShapes._();

  // Expressive Corner Radii
  static const double extraSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
  static const double full = 999.0;

  // Rounded Rectangles
  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(medium)),
  );

  static const RoundedRectangleBorder largeCardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(large)),
  );

  static const RoundedRectangleBorder pillShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(full)),
  );

  static const RoundedRectangleBorder sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(extraLarge)),
  );
}
