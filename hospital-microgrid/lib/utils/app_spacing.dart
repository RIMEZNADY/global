import 'package:flutter/material.dart';



/// Consistent spacing system for the entire app

class AppSpacing {

  // Basée spacing unit

  static const double unit = 4.0;



  // Spacing values

  static const double xs = unit; // 4

  static const double sm = unit * 2; // 8

  static const double md = unit * 4; // 16

  static const double lg = unit * 6; // 24

  static const double xl = unit * 8; // 32

  static const double xxl = unit * 12; // 48



  // Edge insets shortcuts

  static const EdgeInsets xsAll = EdgeInsets.all(xs);

  static const EdgeInsets smAll = EdgeInsets.all(sm);

  static const EdgeInsets mdAll = EdgeInsets.all(md);

  static const EdgeInsets lgAll = EdgeInsets.all(lg);

  static const EdgeInsets xlAll = EdgeInsets.all(xl);



  // Symmetric padding

  static const EdgeInsets smHorizontal = EdgeInsets.symmetric(horizontal: sm);

  static const EdgeInsets mdHorizontal = EdgeInsets.symmetric(horizontal: md);

  static const EdgeInsets lgHorizontal = EdgeInsets.symmetric(horizontal: lg);

  

  static const EdgeInsets smVertical = EdgeInsets.symmetric(vertical: sm);

  static const EdgeInsets mdVertical = EdgeInsets.symmetric(vertical: md);

  static const EdgeInsets lgVertical = EdgeInsets.symmetric(vertical: lg);



  // Page padding (responsive)

  static EdgeInsets pagePadding(BuildContext context) {

    final isMobile = MediaQuery.of(context).size.width < 600;

    return EdgeInsets.all(isMobile ? md : lg);

  }



  // Section spacing

  static const double sectionGap = lg; // 24

  static const double largeSectionGap = xl; // 32



  // Card padding

  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(lg);



  // Input field spacing

  static const double inputSpacing = md; // 16

  static const double inputLabelSpacing = sm; // 8



  // Grid spacing

  static const double gridSpacing = md; // 16

  static const double gridSpacingLarge = lg; // 24

}



/// Consistent border radius

class AppRadius {

  static const double sm = 8.0;

  static const double md = 12.0;

  static const double lg = 16.0;

  static const double xl = 20.0;

  static const double full = 9999.0;



  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));

  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));

  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));

  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));

}



/// Consistent animation durations

class AppDuration {

  static const Duration fast = Duration(milliseconds: 150);

  static const Duration normal = Duration(milliseconds: 300);

  static const Duration slow = Duration(milliseconds: 500);

  static const Duration verySlow = Duration(milliseconds: 800);

}



/// Consistent animation curves

class AppCurves {

  static const Curve standard = Curves.easeInOut;

  static const Curve smooth = Curves.easeOutCubic;

  static const Curve bounce = Curves.elasticOut;

  static const Curve sharp = Curves.easeIn;

}











