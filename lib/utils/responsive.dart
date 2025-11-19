import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Check if mobile
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < mobileBreakpoint;
  }

  // Check if tablet
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  // Check if desktop
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= tabletBreakpoint;
  }

  // Get responsive grid columns
  static int getGridColumns(BuildContext context, {int? maxColumns}) {
    final width = screenWidth(context);
    final max = maxColumns ?? 4;

    if (width < mobileBreakpoint) {
      return 1; // Mobile: 1 column
    } else if (width < tabletBreakpoint) {
      return 2; // Tablet: 2 columns
    } else if (width < desktopBreakpoint) {
      return 3; // Small desktop: 3 columns
    } else {
      return max.clamp(1, 4); // Large desktop: up to max columns
    }
  }

  // Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  // Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  // Get responsive vertical padding
  static double getVerticalPadding(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  // Get responsive spacing
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  // Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    if (isMobile(context)) {
      return 0.9;
    } else if (isTablet(context)) {
      return 1.0;
    } else {
      return 1.1;
    }
  }

  // Get responsive chart height
  static double getChartHeight(BuildContext context, {double? baseHeight}) {
    final base = baseHeight ?? 200.0;
    final height = screenHeight(context);

    if (height < 600) {
      return base * 0.7; // Very small screens
    } else if (height < 800) {
      return base * 0.85; // Small screens
    } else if (isMobile(context)) {
      return base; // Mobile
    } else if (isTablet(context)) {
      return base * 1.2; // Tablet
    } else {
      return base * 1.5; // Desktop
    }
  }

  // Get responsive pie chart size
  static double getPieChartSize(BuildContext context, {double? baseSize}) {
    final base = baseSize ?? 150.0;
    final width = screenWidth(context);

    if (width < mobileBreakpoint) {
      return base * 0.8; // Mobile
    } else if (width < tabletBreakpoint) {
      return base; // Tablet
    } else {
      return base * 1.2; // Desktop
    }
  }

  // Get responsive dialog height
  static double getDialogHeight(BuildContext context, {double? maxHeight}) {
    final height = screenHeight(context);
    final max = maxHeight ?? height * 0.8;

    if (height < 600) {
      return height * 0.7; // Very small screens
    } else if (height < 800) {
      return height * 0.75; // Small screens
    } else {
      return max.clamp(400, height * 0.9); // Normal screens
    }
  }

  // Get responsive width percentage
  static double getWidthPercentage(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }

  // Get responsive height percentage
  static double getHeightPercentage(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }
}

