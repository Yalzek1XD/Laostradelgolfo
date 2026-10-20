import 'package:flutter/widgets.dart';

class Responsive {
  static const double phoneBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phoneBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phoneBreakpoint && width < tabletBreakpoint;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static int gridColumns(
    double width, {
    int phone = 2,
    int tablet = 3,
    int wide = 4,
    double minItemWidth = 150,
  }) {
    if (width < phoneBreakpoint) return phone;
    if (width < tabletBreakpoint) return tablet;
    return (width / minItemWidth).floor().clamp(tablet, wide);
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < phoneBreakpoint) return const EdgeInsets.all(12);
    if (width < tabletBreakpoint) return const EdgeInsets.all(16);
    return const EdgeInsets.all(20);
  }
}
