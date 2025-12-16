import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hospital_microgrid/config/api_config.dart';

class ApiService {
  // URL du backend Spring Boot
  // Utilise ApiConfig pour la configuration centralisée
  static String get baseUrl {
    String url;
    if (kIsWeb) {
      // Web: localhost fonctionne
      url = 'http://localhost:8080/api';
    } else if (Platform.isIOS) {
      // iOS Simulator: localhost fonctionne directement
      url = 'http://localhost:8080/api';
    } else if (Platform.isAndroid) {
      // Android Emulator: utiliser 10.0.2.2 pour accéder au host
      url = 'http://10.0.2.2:8080/api';
    } else {
      // Autres plateformes: utiliser la config par défaut
      url = ApiConfig.backendUrl;
    }
    
    // Debug: afficher l'URL utilisée
    print('🔗 ApiService.baseUrl = $url (isWeb: $kIsWeb, isAndroid: ${!kIsWeb && Platform.isAndroid}, isIOS: ${!kIsWeb && Platform.isIOS})');
    
    return url;
  }
  
  // Récupère le token JWT depuis le stockage local
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Sauvegarde le token JWT
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Supprime le token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Headers avec authentification
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // GET request
  static Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final url = Uri.parse('$baseUrl$endpoint');
    
    // Debug: afficher le token (masqué pour sécurité)
    final token = await _getToken();
    if (token != null) {
      print('🔑 Token present: ${token.substring(0, 20)}...');
    } else {
      print('⚠️ Aucun token trouve pour l\'endpoint: $endpoint');
    }
    
    try {
      final response = await http.get(url, headers: headers);
      
      // Debug: afficher le statut de la réponse
      if (response.statusCode == 403 || response.statusCode == 401) {
        print('❌ Erreur ${response.statusCode} pour $endpoint');
        print('   URL: $url');
        print('   Headers envoyes: ${headers.keys}');
        print('   Token present: ${token != null}');
        print('   Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }
      
      return response;
    } catch (e) {
      print('❌ Exception lors de la requete GET vers $endpoint: $e');
      throw Exception('Erreur reseau: $e');
    }
  }
  
  // POST request
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final url = Uri.parse('$baseUrl$endpoint');
    
    // Debug: afficher le token (masqué pour sécurité)
    final token = await _getToken();
    if (token != null) {
      print('🔑 Token present pour POST: ${token.substring(0, 20)}...');
    } else {
      print('⚠️ Aucun token trouve pour POST vers: $endpoint');
    }
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      // Debug: afficher le statut de la réponse
      if (response.statusCode == 403 || response.statusCode == 401) {
        print('❌ Erreur ${response.statusCode} pour POST $endpoint');
        print('   URL: $url');
        print('   Headers envoyes: ${headers.keys}');
        print('   Token present: ${token != null}');
        print('   Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }
      
      return response;
    } catch (e) {
      print('❌ Exception lors de la requete POST vers $endpoint: $e');
      throw Exception('Erreur reseau: $e');
    }
  }
  
  // PUT request
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
  
  // DELETE request
  static Future<http.Response> delete(String endpoint, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.delete(url, headers: headers);
      return response;
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
  
  // Sauvegarde le token après authentification
  static Future<void> saveAuthToken(String token) async {
    await _saveToken(token);
  }
}

