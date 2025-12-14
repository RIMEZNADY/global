import 'dart:convert';
import 'package:hospital_microgrid/services/api_service.dart';

class AuthService {
  // Login
  static Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await ApiService.post(
        '/auth/login',
        {
          'email': email,
          'password': password,
        },
        includeAuth: false,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Sauvegarder le token
        if (data['token'] != null) {
          await ApiService.saveAuthToken(data['token']);
        }
        
        return AuthResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AuthException('Email ou mot de passe incorrect');
      } else {
        throw AuthException('Erreur de connexion: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Erreur réseau: $e');
    }
  }
  
  // Register
  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await ApiService.post(
        '/auth/register',
        {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          if (phone != null) 'phone': phone,
        },
        includeAuth: false,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Vérifier si le body est vide
        if (response.body.isEmpty) {
          throw AuthException('Réponse vide du serveur');
        }
        
        try {
          final data = jsonDecode(response.body);
          
          // Sauvegarder le token
          if (data['token'] != null) {
            await ApiService.saveAuthToken(data['token']);
          }
          
          return AuthResponse.fromJson(data);
        } on FormatException catch (e) {
          throw AuthException('Erreur de format de réponse: ${e.message}');
        }
      } else if (response.statusCode == 400) {
        // Gérer les erreurs 400
        if (response.body.isNotEmpty) {
          try {
            final error = jsonDecode(response.body);
            throw AuthException(error['message'] ?? 'Erreur lors de l\'inscription');
          } on FormatException {
            throw AuthException('Erreur lors de l\'inscription: ${response.body}');
          }
        } else {
          throw AuthException('Erreur lors de l\'inscription: données invalides');
        }
      } else {
        throw AuthException('Erreur lors de l\'inscription: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Erreur réseau: $e');
    }
  }
  
  // Get current user
  static Future<UserResponse> getCurrentUser() async {
    try {
      final response = await ApiService.get('/auth/me');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AuthException('Non authentifié');
      } else {
        throw AuthException('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Erreur réseau: $e');
    }
  }
  
  // Logout
  static Future<void> logout() async {
    await ApiService.clearToken();
  }
  
  // Vérifier si l'utilisateur est connecté
  static Future<bool> isAuthenticated() async {
    try {
      await getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Modèles de donnes
class AuthResponse {
  final String token;
  final String type;
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
   List<EstablishmentSummary> establishments;
  
  AuthResponse({
    required this.token,
    required this.type,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.establishments,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      type: json['type'] ?? 'Bearer',
      userId: json['userId'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      establishments: (json['establishments'] as List<dynamic>?)
          ?.map((e) => EstablishmentSummary.fromJson(e))
          .toList() ?? [],
    );
  }
}

class UserResponse {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final bool active;
  final DateTime createdAt;
   List<EstablishmentSummary> establishments;
  
  UserResponse({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    required this.active,
    required this.createdAt,
    required this.establishments,
  });
  
  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'USER',
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      establishments: (json['establishments'] as List<dynamic>?)
          ?.map((e) => EstablishmentSummary.fromJson(e))
          .toList() ?? [],
    );
  }
}

class EstablishmentSummary {
  final int id;
  final String name;
  final String type;
  final String status;
  final DateTime? createdAt;
  
  EstablishmentSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.createdAt,
  });
  
  factory EstablishmentSummary.fromJson(Map<String, dynamic> json) {
    return EstablishmentSummary(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }
}

// Exception personnalisée
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}


