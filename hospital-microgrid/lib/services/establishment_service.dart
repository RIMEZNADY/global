import 'dart:convert';
import 'package:hospital_microgrid/services/api_service.dart';

class EstablishmentService {
  // Créer un établissement
  static Future<EstablishmentResponse> createEstablishment(EstablishmentRequest request) async {
    try {
      final response = await ApiService.post('/establishments', request.toJson());
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EstablishmentResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw EstablishmentException(error['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      if (e is EstablishmentException) {
        rethrow;
      }
      throw EstablishmentException('Erreur réseau: $e');
    }
  }
  
  // Récupérer tous les établissements de l'utilisateur
  static Future<List<EstablishmentResponse>> getUserEstablishments() async {
    try {
      final response = await ApiService.get('/establishments');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((e) => EstablishmentResponse.fromJson(e)).toList();
      } else {
        throw EstablishmentException('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      if (e is EstablishmentException) {
        rethrow;
      }
      throw EstablishmentException('Erreur réseau: $e');
    }
  }
  
  // Récupérer un établissement par ID
  static Future<EstablishmentResponse> getEstablishment(int id) async {
    try {
      final response = await ApiService.get('/establishments/$id');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EstablishmentResponse.fromJson(data);
      } else {
        throw EstablishmentException('Établissement non trouvé');
      }
    } catch (e) {
      if (e is EstablishmentException) {
        rethrow;
      }
      throw EstablishmentException('Erreur réseau: $e');
    }
  }
  
  // Mettre à jour un établissement
  static Future<EstablishmentResponse> updateEstablishment(int id, EstablishmentRequest request) async {
    try {
      final response = await ApiService.put('/establishments/$id', request.toJson());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EstablishmentResponse.fromJson(data);
      } else {
        throw EstablishmentException('Erreur lors de la mise à jour');
      }
    } catch (e) {
      if (e is EstablishmentException) {
        rethrow;
      }
      throw EstablishmentException('Erreur réseau: $e');
    }
  }
  
  // Supprimer un Ã©tablissement
  static Future<void> deleteEstablishment(int id) async {
    try {
      final response = await ApiService.delete('/establishments/$id');
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw EstablishmentException('Erreur lors de la suppression');
      }
    } catch (e) {
      if (e is EstablishmentException) {
        rethrow;
      }
      throw EstablishmentException('Erreur réseau: $e');
    }
  }
  
  // Récupérer les recommandations de dimensionnement
  static Future<RecommendationsResponse> getRecommendations(int id) async {
    try {
      final response = await ApiService.get('/establishments/$id/recommendations');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RecommendationsResponse.fromJson(data);
      } else {
        throw EstablishmentException('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      if (e is EstablishmentException) {
        rethrow;
      }
      throw EstablishmentException('Erreur réseau: $e');
    }
  }
  
  // Récupérer les économies et indicateurs économiques
  static Future<SavingsResponse> getSavings(int id, {double electricityPriceDhPerKwh = 1.2}) async {
    try {
      final response = await ApiService.get('/establishments/$id/savings?electricityPriceDhPerKwh=$electricityPriceDhPerKwh');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SavingsResponse.fromJson(data);
      } else {
        throw EstablishmentException('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      if (e is EstablishmentException) {
        rethrow;
      }
      throw EstablishmentException('Erreur réseau: $e');
    }
  }
  
  // Récupérer tous les résultats complets (impact environnemental, score global, etc.)
  static Future<Map<String, dynamic>> getComprehensiveResults(int id) async {
    try {
      // Essayer d'abord avec authentification
      var response = await ApiService.get('/establishments/$id/comprehensive-results', includeAuth: true);
      
      // Si 403, essayer sans authentification (pour les tests)
      if (response.statusCode == 403 || response.statusCode == 401) {
        print('⚠️ Erreur ${response.statusCode}, tentative sans authentification...');
        response = await ApiService.get('/establishments/$id/comprehensive-results', includeAuth: false);
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw EstablishmentException('Accès refusé (403). Vérifiez que l\'établissement existe et que vous y avez accès.');
      } else if (response.statusCode == 401) {
        throw EstablishmentException('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 404) {
        throw EstablishmentException('Établissement non trouvé (ID: $id)');
      } else {
        final errorBody = response.body;
        throw EstablishmentException('Erreur ${response.statusCode}: ${errorBody.isNotEmpty ? errorBody : "Erreur serveur"}');
      }
    } catch (e) {
      if (e is EstablishmentException) {
        rethrow;
      }
      throw EstablishmentException('Erreur réseau: $e');
    }
  }
}

// Modèle de requête
class EstablishmentRequest {
  final String name;
  final String type; // CHU, HOPITAL_REGIONAL, etc.
  final int numberOfBeds;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? irradiationClass; // A, B, C, D
  final double? installableSurfaceM2;
  final double? nonCriticalSurfaceM2;
  final double? monthlyConsumptionKwh;
  final bool? existingPvInstalled;
  final double? existingPvPowerKwc;
  final double? projectBudgetDh;
  final double? totalAvailableSurfaceM2;
  final int? populationServed;
  final String? projectPriority; // MINIMIZE_COST, MAXIMIZE_AUTONOMY, etc.
  
  EstablishmentRequest({
    required this.name,
    required this.type,
    required this.numberOfBeds,
    this.address,
    this.latitude,
    this.longitude,
    this.irradiationClass,
    this.installableSurfaceM2,
    this.nonCriticalSurfaceM2,
    this.monthlyConsumptionKwh,
    this.existingPvInstalled,
    this.existingPvPowerKwc,
    this.projectBudgetDh,
    this.totalAvailableSurfaceM2,
    this.populationServed,
    this.projectPriority,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'numberOfBeds': numberOfBeds,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (irradiationClass != null) 'irradiationClass': irradiationClass,
      if (installableSurfaceM2 != null) 'installableSurfaceM2': installableSurfaceM2,
      if (nonCriticalSurfaceM2 != null) 'nonCriticalSurfaceM2': nonCriticalSurfaceM2,
      if (monthlyConsumptionKwh != null) 'monthlyConsumptionKwh': monthlyConsumptionKwh,
      if (existingPvInstalled != null) 'existingPvInstalled': existingPvInstalled,
      if (existingPvPowerKwc != null) 'existingPvPowerKwc': existingPvPowerKwc,
      if (projectBudgetDh != null) 'projectBudgetDh': projectBudgetDh,
      if (totalAvailableSurfaceM2 != null) 'totalAvailableSurfaceM2': totalAvailableSurfaceM2,
      if (populationServed != null) 'populationServed': populationServed,
      if (projectPriority != null) 'projectPriority': projectPriority,
    };
  }
}

// Modèle de réponse
class EstablishmentResponse {
  final int id;
  final String name;
  final String type;
  final int numberOfBeds;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? irradiationClass;
  final double? installableSurfaceM2;
  final double? nonCriticalSurfaceM2;
  final double? monthlyConsumptionKwh;
  final bool? existingPvInstalled;
  final double? existingPvPowerKwc;
  final double? projectBudgetDh;
  final double? totalAvailableSurfaceM2;
  final int? populationServed;
  final String? projectPriority;
  final String status;
  final DateTime? createdAt;
  
  EstablishmentResponse({
    required this.id,
    required this.name,
    required this.type,
    required this.numberOfBeds,
    this.address,
    this.latitude,
    this.longitude,
    this.irradiationClass,
    this.installableSurfaceM2,
    this.nonCriticalSurfaceM2,
    this.monthlyConsumptionKwh,
    this.existingPvInstalled,
    this.existingPvPowerKwc,
    this.projectBudgetDh,
    this.totalAvailableSurfaceM2,
    this.populationServed,
    this.projectPriority,
    required this.status,
    this.createdAt,
  });
  
  factory EstablishmentResponse.fromJson(Map<String, dynamic> json) {
    return EstablishmentResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      numberOfBeds: json['numberOfBeds'] ?? 0,
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      irradiationClass: json['irradiationClass'],
      installableSurfaceM2: json['installableSurfaceM2']?.toDouble(),
      nonCriticalSurfaceM2: json['nonCriticalSurfaceM2']?.toDouble(),
      monthlyConsumptionKwh: json['monthlyConsumptionKwh']?.toDouble(),
      existingPvInstalled: json['existingPvInstalled'],
      existingPvPowerKwc: json['existingPvPowerKwc']?.toDouble(),
      projectBudgetDh: json['projectBudgetDh']?.toDouble(),
      totalAvailableSurfaceM2: json['totalAvailableSurfaceM2']?.toDouble(),
      populationServed: json['populationServed'],
      projectPriority: json['projectPriority'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }
}

// Modèle de réponse pour les recommandations
class RecommendationsResponse {
  final double recommendedPvPower;
  final double recommendedPvSurface;
  final double recommendedBatteryCapacity;
  final double energyAutonomy;
  final double annualSavings;
  final double roi;
  final String message;
  
  RecommendationsResponse({
    required this.recommendedPvPower,
    required this.recommendedPvSurface,
    required this.recommendedBatteryCapacity,
    required this.energyAutonomy,
    required this.annualSavings,
    required this.roi,
    required this.message,
  });
  
  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationsResponse(
      recommendedPvPower: (json['recommendedPvPowerKwc'] ?? json['recommendedPvPower'] ?? 0.0).toDouble(),
      recommendedPvSurface: (json['recommendedPvSurfaceM2'] ?? json['recommendedPvSurface'] ?? 0.0).toDouble(),
      recommendedBatteryCapacity: (json['recommendedBatteryCapacityKwh'] ?? json['recommendedBatteryCapacity'] ?? 0.0).toDouble(),
      energyAutonomy: (json['estimatedEnergyAutonomy'] ?? json['energyAutonomy'] ?? 0.0).toDouble(),
      annualSavings: (json['estimatedAnnualSavings'] ?? json['annualSavings'] ?? 0.0).toDouble(),
      roi: (json['estimatedROI'] ?? json['roi'] ?? 0.0).toDouble(),
      message: json['description'] ?? json['message'] ?? '',
    );
  }
}

// Modèle de réponse pour les économies
class SavingsResponse {
  final double annualConsumption;
  final double annualPvProduction;
  final double annualSavings;
  final double energyAutonomy;
  final double annualBillAfterPv;
  
  SavingsResponse({
    required this.annualConsumption,
    required this.annualPvProduction,
    required this.annualSavings,
    required this.energyAutonomy,
    required this.annualBillAfterPv,
  });
  
  factory SavingsResponse.fromJson(Map<String, dynamic> json) {
    return SavingsResponse(
      annualConsumption: (json['annualConsumption'] ?? 0.0).toDouble(),
      annualPvProduction: (json['annualPvEnergy'] ?? json['annualPvProduction'] ?? 0.0).toDouble(),
      annualSavings: (json['annualSavings'] ?? 0.0).toDouble(),
      energyAutonomy: (json['autonomyPercentage'] ?? json['energyAutonomy'] ?? 0.0).toDouble(),
      annualBillAfterPv: (json['annualBillAfterPv'] ?? 0.0).toDouble(),
    );
  }
}

// Exception personnalisée
class EstablishmentException implements Exception {
  final String message;
  EstablishmentException(this.message);
  
  @override
  String toString() => message;
}

