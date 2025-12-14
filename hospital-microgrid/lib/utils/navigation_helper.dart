import 'package:flutter/material.dart';
import 'package:hospital_microgrid/utils/page_transitions.dart';

/// Helper class for consistent navigation throughout the app
class NavigationHelper {
 /// Navigate to a page with smooth transition
 static Future<T?> push<T extends Object>(
 BuildContext context,
 Widget page, {
 bool useSlide = true,
 }) {
 return Navigator.push<T>(
 context,
 AppPageTransitions.smoothRoute(
 page,
 useSlide: useSlide,
 ),
 );
 }

 /// Navigate and replace current page
 static Future<T?> pushReplacement<T extends Object, TO extends Object>(
 BuildContext context,
 Widget page, {
 bool useSlide = true,
 TO? result,
 }) {
 return Navigator.pushReplacement<T, TO>(
 context,
 AppPageTransitions.smoothRoute(
 page,
 useSlide: useSlide,
 ),
 result: result,
 );
 }

 /// Navigate and remove all previous routes
 static Future<T?> pushAndRemoveUntil<T extends Object>(
 BuildContext context,
 Widget page, {
 bool useSlide = true,
 }) {
 return Navigator.pushAndRemoveUntil<T>(
 context,
 AppPageTransitions.smoothRoute(
 page,
 useSlide: useSlide,
 ),
 (route) => false,
 );
 }

 /// Show a modal (slides from bottom)
 static Future<T?> showModal<T extends Object>(
 BuildContext context,
 Widget page,
 ) {
 return Navigator.push<T>(
 context,
 AppPageTransitions.modalRoute(page),
 );
 }

 /// Pop current route with optional result
 static void pop<T extends Object>(BuildContext context, [T? result]) {
 Navigator.pop<T>(context, result);
 }

 /// Check if can pop
 static bool canPop(BuildContext context) {
 return Navigator.canPop(context);
 }
}


