import 'package:flutter/material.dart';



/// Custom page transitions for smooth navigation

class AppPageTransitions {

  /// Smooth fade transition (default)

  static Widget fadeTransition(

    BuildContext context,

    Animation<double> animation,

    Animation<double> secondaryAnimation,

    Widget child,

  ) {

    return FadeTransition(

      opacity: CurvedAnimation(

        parent: animation,

        curve: Curves.easeInOut,

      ),

      child: child,

    );

  }



  /// Smooth slide transition from right

  static Widget slideTransition(

    BuildContext context,

    Animation<double> animation,

    Animation<double> secondaryAnimation,

    Widget child,

  ) {

    const begin = Offset(1.0, 0.0);

    const end = Offset.zero;

    const curve = Curves.easeOutCubic;



    var tween = Tween(begin: begin, end: end).chain(

      CurveTween(curve: curve),

    );



    return SlideTransition(

      position: animation.drive(tween),

      child: FadeTransition(

        opacity: animation,

        child: child,

      ),

    );

  }



  /// Smooth scale and fade transition

  static Widget scaleTransition(

    BuildContext context,

    Animation<double> animation,

    Animation<double> secondaryAnimation,

    Widget child,

  ) {

    return ScaleTransition(

      scale: Tween<double>(

        begin: 0.95,

        end: 1.0,

      ).animate(

        CurvedAnimation(

          parent: animation,

          curve: Curves.easeOutCubic,

        ),

      ),

      child: FadeTransition(

        opacity: animation,

        child: child,

      ),

    );

  }



  /// Smooth slide from bottom (for dialogs/modals)

  static Widget slideUpTransition(

    BuildContext context,

    Animation<double> animation,

    Animation<double> secondaryAnimation,

    Widget child,

  ) {

    const begin = Offset(0.0, 1.0);

    const end = Offset.zero;

    const curve = Curves.easeOutCubic;



    var tween = Tween(begin: begin, end: end).chain(

      CurveTween(curve: curve),

    );



    return SlideTransition(

      position: animation.drive(tween),

      child: child,

    );

  }



  /// Creates a smooth page route

  static PageRoute<T> smoothRoute<T extends Object>(

    Widget page, {

    bool useSlide = true,

    Duration duration = const Duration(milliseconds: 300),

  }) {

    return PageRouteBuilder<T>(

      pageBuilder: (context, animation, secondaryAnimation) => page,

      transitionDuration: duration,

      reverseTransitionDuration: duration,

      transitionsBuilder: useSlide ? slideTransition : fadeTransition,

    );

  }



  /// Creates a modal-style route (slides from bottom)

  static PageRoute<T> modalRoute<T extends Object>(

    Widget page, {

    Duration duration = const Duration(milliseconds: 350),

  }) {

    return PageRouteBuilder<T>(

      pageBuilder: (context, animation, secondaryAnimation) => page,

      transitionDuration: duration,

      reverseTransitionDuration: duration,

      transitionsBuilder: slideUpTransition,

      opaque: false,

      barrierDismissible: true,

      barrierColor: Colors.black54,

    );

  }

}











