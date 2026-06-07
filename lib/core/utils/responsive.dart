import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class Responsive {
  static ScreenType of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return ScreenType.mobile;
    if (width < 1100) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenType.desktop;

  static double contentMaxWidth(BuildContext context) {
    return switch (of(context)) {
      ScreenType.mobile => double.infinity,
      ScreenType.tablet => 900,
      ScreenType.desktop => 1400,
    };
  }
}
