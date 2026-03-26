import 'package:flutter/material.dart';

/// Helper class for responsive layouts
///
/// Breakpoints:
/// - Phone: < 600px
/// - Tablet: 600px - 900px
/// - Desktop/Large Tablet: > 900px
class ResponsiveHelper {
  static const double phoneBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double maxContentWidth = 1200;

  /// Get the device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return DeviceType.phone;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is a phone
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < phoneBreakpoint;
  }

  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= phoneBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is a large screen (tablet landscape or desktop)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Is landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get adaptive grid cross axis count for service/feature cards
  /// - Phone: 2 columns
  /// - Tablet portrait: 3 columns
  /// - Tablet landscape/Desktop: 4 columns
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 2;
    } else if (width < tabletBreakpoint) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get adaptive grid cross axis count for product cards (smaller cards)
  /// - Phone: 2 columns
  /// - Tablet portrait: 3 columns
  /// - Tablet landscape/Desktop: 4-5 columns
  static int getProductGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 2;
    } else if (width < 750) {
      return 3;
    } else if (width < tabletBreakpoint) {
      return 4;
    } else {
      return 5;
    }
  }

  /// Get adaptive grid cross axis count for stats cards
  /// - Phone: 2 columns
  /// - Tablet portrait: 3 columns
  /// - Tablet landscape/Desktop: 4 columns
  static int getStatsGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 2;
    } else if (width < tabletBreakpoint) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get child aspect ratio for service cards based on screen size
  static double getServiceCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 0.92; // Cartes plus hautes sur téléphone
    } else if (width < tabletBreakpoint) {
      return 1.0; // Carrées sur tablette
    } else {
      return 1.05; // Légèrement plus larges sur grand écran
    }
  }

  /// Get child aspect ratio for product cards based on screen size
  static double getProductCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 0.7;
    } else if (width < tabletBreakpoint) {
      return 0.75;
    } else {
      return 0.8;
    }
  }

  /// Get child aspect ratio for stats cards based on screen size
  static double getStatsCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 1.1;
    } else if (width < tabletBreakpoint) {
      return 1.2;
    } else {
      return 1.3;
    }
  }

  /// Get adaptive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 16.0;
    } else if (width < tabletBreakpoint) {
      return 24.0;
    } else {
      // On very large screens, calculate padding to center content
      return ((width - maxContentWidth) / 2).clamp(32.0, double.infinity);
    }
  }

  /// Get adaptive spacing between grid items
  static double getGridSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 18.0;
    } else if (width < tabletBreakpoint) {
      return 22.0;
    } else {
      return 28.0;
    }
  }

  /// Get adaptive card elevation
  static double getCardElevation(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 2.0;
    } else {
      return 4.0;
    }
  }

  /// Get adaptive card border radius
  static double getCardBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  /// Get adaptive icon size for feature cards
  static double getFeatureIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 32.0;
    } else if (width < tabletBreakpoint) {
      return 40.0;
    } else {
      return 48.0;
    }
  }

  /// Get adaptive title font size
  static double getTitleFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 14.0;
    } else if (width < tabletBreakpoint) {
      return 16.0;
    } else {
      return 18.0;
    }
  }

  /// Get adaptive header font size
  static double getHeaderFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return 20.0;
    } else if (width < tabletBreakpoint) {
      return 24.0;
    } else {
      return 28.0;
    }
  }

  /// Get adaptive dialog width
  static double getDialogWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return width * 0.9;
    } else if (width < tabletBreakpoint) {
      return 500.0;
    } else {
      return 600.0;
    }
  }

  /// Get adaptive form field width for larger screens
  static double? getFormFieldMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) {
      return 600.0;
    }
    return null; // No max width on smaller screens
  }

  /// Build responsive SliverGridDelegate for product grids
  static SliverGridDelegate buildProductGridDelegate(BuildContext context) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: getProductGridCrossAxisCount(context),
      crossAxisSpacing: getGridSpacing(context),
      mainAxisSpacing: getGridSpacing(context),
      childAspectRatio: getProductCardAspectRatio(context),
    );
  }

  /// Build responsive SliverGridDelegate for service cards
  static SliverGridDelegate buildServiceGridDelegate(BuildContext context) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: getGridCrossAxisCount(context),
      crossAxisSpacing: getGridSpacing(context),
      mainAxisSpacing: getGridSpacing(context),
      childAspectRatio: getServiceCardAspectRatio(context),
    );
  }

  /// Build responsive SliverGridDelegate for stats cards
  static SliverGridDelegate buildStatsGridDelegate(BuildContext context) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: getStatsGridCrossAxisCount(context),
      crossAxisSpacing: getGridSpacing(context),
      mainAxisSpacing: getGridSpacing(context),
      childAspectRatio: getStatsCardAspectRatio(context),
    );
  }

  /// Get list view item padding for larger screens
  static EdgeInsets getListItemPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 10);
    } else {
      // Center content on very large screens
      final horizontalPadding =
          ((width - maxContentWidth) / 2).clamp(32.0, double.infinity);
      return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12);
    }
  }
}

/// Device type enum
enum DeviceType {
  phone,
  tablet,
  desktop,
}

/// Extension on BuildContext for easy responsive access
extension ResponsiveContext on BuildContext {
  bool get isPhone => ResponsiveHelper.isPhone(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isLargeScreen => ResponsiveHelper.isLargeScreen(this);
  bool get isLandscape => ResponsiveHelper.isLandscape(this);
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);
  double get screenWidth => ResponsiveHelper.screenWidth(this);
  double get screenHeight => ResponsiveHelper.screenHeight(this);
}

/// Responsive builder widget for conditional layouts
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper.getDeviceType(context));
  }
}

/// Widget that constrains its child to a maximum width (useful for large screens)
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final CrossAxisAlignment alignment;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveHelper.maxContentWidth,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment == CrossAxisAlignment.start
          ? Alignment.centerLeft
          : alignment == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
