import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';



/// Service pour sauvegarder et restaurer les brouillons de formulaires

class DraftService {

  static const String _draftKeyPrefix = 'establishment_draft_';

  static final String _draftFormA1Key = '${_draftKeyPrefix}form_a1';

  static final String _draftFormA2Key = '${_draftKeyPrefix}form_a2';

  static final String _draftFormA5Key = '${_draftKeyPrefix}form_a5';



  /// Sauvegarde les données de FormA1

  static Future<void> saveFormA1Draft({

    required String institutionType,

    required String institutionName,

    required int numberOfBeds,

    required double? latitude,

    required double? longitude,

  }) async {

    final prefs = await SharedPreferences.getInstance();

    final draft = {

      'institutionType': institutionType,

      'institutionName': institutionName,

      'numberOfBeds': numberOfBeds,

      'latitude': latitude,

      'longitude': longitude,

      'savedAt': DateTime.now().toIso8601String(),

    };

    await prefs.setString(_draftFormA1Key, jsonEncode(draft));

  }



  /// Récupère les données de FormA1

  static Future<Map<String, dynamic>?> getFormA1Draft() async {

    final prefs = await SharedPreferences.getInstance();

    final draftJson = prefs.getString(_draftFormA1Key);

    if (draftJson == null) return null;

    return jsonDecode(draftJson) as Map<String, dynamic>;

  }



  /// Sauvegarde les données de FormA2

  static Future<void> saveFormA2Draft({

    required double? solarSurface,

    required double? solarSurfaceMin,

    required double? solarSurfaceMax,

    required bool useIntervalSolar,

    required double? nonCriticalSurface,

    required double? nonCriticalSurfaceMin,

    required double? nonCriticalSurfaceMax,

    required bool useIntervalNonCritical,

    required double? monthlyConsumption,

    required double? monthlyConsumptionMin,

    required double? monthlyConsumptionMax,

    required bool useIntervalConsumption,

  }) async {

    final prefs = await SharedPreferences.getInstance();

    final draft = {

      'solarSurface': solarSurface,

      'solarSurfaceMin': solarSurfaceMin,

      'solarSurfaceMax': solarSurfaceMax,

      'useIntervalSolar': useIntervalSolar,

      'nonCriticalSurface': nonCriticalSurface,

      'nonCriticalSurfaceMin': nonCriticalSurfaceMin,

      'nonCriticalSurfaceMax': nonCriticalSurfaceMax,

      'useIntervalNonCritical': useIntervalNonCritical,

      'monthlyConsumption': monthlyConsumption,

      'monthlyConsumptionMin': monthlyConsumptionMin,

      'monthlyConsumptionMax': monthlyConsumptionMax,

      'useIntervalConsumption': useIntervalConsumption,

      'savedAt': DateTime.now().toIso8601String(),

    };

    await prefs.setString(_draftFormA2Key, jsonEncode(draft));

  }



  /// Récupère les données de FormA2

  static Future<Map<String, dynamic>?> getFormA2Draft() async {

    final prefs = await SharedPreferences.getInstance();

    final draftJson = prefs.getString(_draftFormA2Key);

    if (draftJson == null) return null;

    return jsonDecode(draftJson) as Map<String, dynamic>;

  }



  /// Sauvegarde les données de FormA5

  static Future<void> saveFormA5Draft({

    required String? selectedPanel,

    required String? selectedBattery,

    required String? selectedInverter,

    required String? selectedController,

  }) async {

    final prefs = await SharedPreferences.getInstance();

    final draft = {

      'selectedPanel': selectedPanel,

      'selectedBattery': selectedBattery,

      'selectedInverter': selectedInverter,

      'selectedController': selectedController,

      'savedAt': DateTime.now().toIso8601String(),

    };

    await prefs.setString(_draftFormA5Key, jsonEncode(draft));

  }



  /// Récupère les données de FormA5

  static Future<Map<String, dynamic>?> getFormA5Draft() async {

    final prefs = await SharedPreferences.getInstance();

    final draftJson = prefs.getString(_draftFormA5Key);

    if (draftJson == null) return null;

    return jsonDecode(draftJson) as Map<String, dynamic>;

  }



  /// Supprime tous les brouillons

  static Future<void> clearAllDrafts() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_draftFormA1Key);

    await prefs.remove(_draftFormA2Key);

    await prefs.remove(_draftFormA5Key);

  }



  /// Vérifie si un brouillon existe

  static Future<bool> hasDraft() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(_draftFormA1Key) ||

        prefs.containsKey(_draftFormA2Key) ||

        prefs.containsKey(_draftFormA5Key);

  }

}

















