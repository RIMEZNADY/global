# 🌐 REST API - Comment ça fonctionne dans le projet

## 🎯 Vue d'Ensemble

Le projet utilise une **architecture REST API** pour la communication entre le **Frontend Flutter** et le **Backend Spring Boot**. Les endpoints sont **définis statiquement** dans le backend, mais les **appels sont dynamiques** depuis le frontend.

---

## 🏗️ Architecture REST API

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND FLUTTER                          │
│                                                              │
│  ApiService (Service centralisé)                            │
│  ├─ get(endpoint)                                           │
│  ├─ post(endpoint, body)                                    │
│  ├─ put(endpoint, body)                                     │
│  └─ delete(endpoint)                                        │
│                                                              │
│  Services métier (EstablishmentService, AuthService, etc.)  │
│  └─ Utilisent ApiService pour appeler les endpoints        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTP/REST (JSON)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│              BACKEND SPRING BOOT                            │
│                                                              │
│  Controllers (Annotations @RestController)                  │
│  ├─ @GetMapping("/api/establishments")                      │
│  ├─ @PostMapping("/api/establishments")                     │
│  ├─ @PutMapping("/api/establishments/{id}")                 │
│  └─ @DeleteMapping("/api/establishments/{id}")              │
│                                                              │
│  Services métier (EstablishmentService, etc.)               │
│  └─ Logique métier et calculs                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📡 Côté Backend (Spring Boot)

### **1. Définition des Endpoints (Statique)**

Les endpoints sont définis avec des **annotations Spring Boot** dans les contrôleurs.

#### **Exemple : EstablishmentController**

```java
@RestController
@RequestMapping("/api/establishments")
@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:3000"})
public class EstablishmentController {
    
    @Autowired
    private EstablishmentService establishmentService;
    
    // GET /api/establishments
    @GetMapping
    public ResponseEntity<List<EstablishmentResponse>> getAllEstablishments(
        Authentication authentication
    ) {
        Long userId = ((UserPrincipal) authentication.getPrincipal()).getId();
        List<Establishment> establishments = establishmentService.findAllByUserId(userId);
        List<EstablishmentResponse> responses = establishments.stream()
            .map(EstablishmentResponse::fromEntity)
            .collect(Collectors.toList());
        return ResponseEntity.ok(responses);
    }
    
    // POST /api/establishments
    @PostMapping
    public ResponseEntity<?> createEstablishment(
        @Valid @RequestBody EstablishmentRequest request,
        Authentication authentication
    ) {
        Long userId = ((UserPrincipal) authentication.getPrincipal()).getId();
        Establishment establishment = establishmentService.create(request, userId);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(EstablishmentResponse.fromEntity(establishment));
    }
    
    // GET /api/establishments/{id}
    @GetMapping("/{id}")
    public ResponseEntity<EstablishmentResponse> getEstablishment(
        @PathVariable Long id,
        Authentication authentication
    ) {
        Long userId = ((UserPrincipal) authentication.getPrincipal()).getId();
        Establishment establishment = establishmentService.findByIdAndUserId(id, userId);
        return ResponseEntity.ok(EstablishmentResponse.fromEntity(establishment));
    }
    
    // PUT /api/establishments/{id}
    @PutMapping("/{id}")
    public ResponseEntity<EstablishmentResponse> updateEstablishment(
        @PathVariable Long id,
        @Valid @RequestBody EstablishmentRequest request,
        Authentication authentication
    ) {
        Long userId = ((UserPrincipal) authentication.getPrincipal()).getId();
        Establishment establishment = establishmentService.update(id, request, userId);
        return ResponseEntity.ok(EstablishmentResponse.fromEntity(establishment));
    }
    
    // DELETE /api/establishments/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEstablishment(
        @PathVariable Long id,
        Authentication authentication
    ) {
        Long userId = ((UserPrincipal) authentication.getPrincipal()).getId();
        establishmentService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
    
    // GET /api/establishments/{id}/comprehensive-results
    @GetMapping("/{id}/comprehensive-results")
    public ResponseEntity<Map<String, Object>> getComprehensiveResults(
        @PathVariable Long id,
        Authentication authentication
    ) {
        Long userId = ((UserPrincipal) authentication.getPrincipal()).getId();
        Map<String, Object> results = comprehensiveResultsService.calculateAllResults(id, userId);
        return ResponseEntity.ok(results);
    }
}
```

#### **Annotations Spring Boot utilisées :**

| Annotation | Usage |
|------------|-------|
| `@RestController` | Marque la classe comme contrôleur REST |
| `@RequestMapping("/api/establishments")` | Préfixe de base pour tous les endpoints |
| `@GetMapping` | Endpoint GET |
| `@PostMapping` | Endpoint POST |
| `@PutMapping` | Endpoint PUT |
| `@DeleteMapping` | Endpoint DELETE |
| `@PathVariable` | Variable dans l'URL (`{id}`) |
| `@RequestBody` | Corps de la requête (JSON) |
| `@RequestParam` | Paramètre de requête (`?param=value`) |
| `@CrossOrigin` | Configuration CORS |

---

### **2. Structure des Controllers**

#### **AuthController** (`/api/auth`)

```java
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        // Logique d'inscription
    }
    
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        // Logique de connexion
    }
    
    @GetMapping("/me")
    public ResponseEntity<UserResponse> getCurrentUser(Authentication authentication) {
        // Récupérer l'utilisateur connecté
    }
}
```

#### **LocationController** (`/api/location`)

```java
@RestController
@RequestMapping("/api/location")
public class LocationController {
    
    @GetMapping("/irradiation")
    public ResponseEntity<IrradiationResponse> getIrradiationClass(
        @RequestParam double latitude,
        @RequestParam double longitude
    ) {
        // Déterminer la classe d'irradiation
    }
    
    @GetMapping("/estimate-population")
    public ResponseEntity<Map<String, Object>> estimatePopulation(
        @RequestParam double latitude,
        @RequestParam double longitude
    ) {
        // Estimer la population
    }
}
```

---

## 📱 Côté Frontend (Flutter)

### **1. Service API Centralisé (Dynamique)**

**ApiService** : Service centralisé pour tous les appels HTTP

```dart
class ApiService {
  // URL de base (dynamique selon la plateforme)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else {
      return ApiConfig.backendUrl; // http://10.0.2.2:8080/api pour Android
    }
  }
  
  // GET request (dynamique)
  static Future<http.Response> get(
    String endpoint,  // ← Endpoint dynamique
    {bool includeAuth = true, Duration? timeout}
  ) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final url = Uri.parse('$baseUrl$endpoint'); // ← Construction dynamique de l'URL
    
    final response = await http.get(url, headers: headers);
    return response;
  }
  
  // POST request (dynamique)
  static Future<http.Response> post(
    String endpoint,  // ← Endpoint dynamique
    Map<String, dynamic> body,  // ← Body dynamique
    {bool includeAuth = true}
  ) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final url = Uri.parse('$baseUrl$endpoint');
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body), // ← Encodage JSON dynamique
    );
    return response;
  }
  
  // PUT request
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
    {bool includeAuth = true}
  ) async {
    // Similaire à POST
  }
  
  // DELETE request
  static Future<http.Response> delete(
    String endpoint,
    {bool includeAuth = true}
  ) async {
    // Similaire à GET
  }
}
```

**Points clés :**
- ✅ **Endpoints dynamiques** : Passés en paramètre
- ✅ **URL construite dynamiquement** : `baseUrl + endpoint`
- ✅ **Body dynamique** : Map<String, dynamic> encodé en JSON
- ✅ **Headers automatiques** : JWT token inclus automatiquement

---

### **2. Services Métier (Utilisation d'ApiService)**

#### **Exemple : EstablishmentService**

```dart
class EstablishmentService {
  // Créer un établissement
  static Future<EstablishmentResponse> createEstablishment(
    EstablishmentRequest request
  ) async {
    // Appel dynamique à l'endpoint
    final response = await ApiService.post(
      '/establishments',  // ← Endpoint dynamique
      request.toJson(),   // ← Body dynamique (objet → JSON)
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return EstablishmentResponse.fromJson(data);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
  
  // Récupérer tous les établissements
  static Future<List<EstablishmentResponse>> getAllEstablishments() async {
    final response = await ApiService.get('/establishments');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => EstablishmentResponse.fromJson(e)).toList();
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
  
  // Récupérer un établissement par ID
  static Future<EstablishmentResponse> getEstablishment(int id) async {
    final response = await ApiService.get('/establishments/$id'); // ← ID dynamique
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EstablishmentResponse.fromJson(data);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
  
  // Mettre à jour un établissement
  static Future<EstablishmentResponse> updateEstablishment(
    int id,
    EstablishmentRequest request
  ) async {
    final response = await ApiService.put(
      '/establishments/$id',  // ← ID dynamique dans l'URL
      request.toJson(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EstablishmentResponse.fromEntity(data);
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
  
  // Supprimer un établissement
  static Future<void> deleteEstablishment(int id) async {
    final response = await ApiService.delete('/establishments/$id');
    
    if (response.statusCode != 204) {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
  
  // Récupérer les résultats complets
  static Future<Map<String, dynamic>> getComprehensiveResults(int id) async {
    final response = await ApiService.get('/establishments/$id/comprehensive-results');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  }
}
```

---

## 🔄 Flux Complet d'un Appel REST API

### **Exemple : Créer un établissement**

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Frontend : Utilisateur remplit le formulaire            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Frontend : EstablishmentService.createEstablishment()    │
│    - Crée EstablishmentRequest                              │
│    - Appelle ApiService.post('/establishments', request)    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. ApiService.post()                                        │
│    - Récupère token JWT depuis SharedPreferences            │
│    - Construit URL : http://localhost:8080/api/establishments│
│    - Encode body en JSON : jsonEncode(request.toJson())     │
│    - Ajoute headers : Authorization: Bearer <token>         │
│    - Envoie HTTP POST                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTP POST
                       │ Headers: {
                       │   Content-Type: application/json
                       │   Authorization: Bearer <token>
                       │ }
                       │ Body: {
                       │   "name": "CHU Casablanca",
                       │   "type": "CHU",
                       │   ...
                       │ }
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Backend : Spring Boot reçoit la requête                 │
│    - JwtAuthenticationFilter valide le token                │
│    - Route vers EstablishmentController.createEstablishment()│
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Backend : EstablishmentController                        │
│    - @PostMapping("/api/establishments")                    │
│    - @RequestBody EstablishmentRequest                      │
│    - Appelle EstablishmentService.create()                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Backend : EstablishmentService                           │
│    - Valide les données                                     │
│    - Crée l'entité Establishment                            │
│    - Sauvegarde dans PostgreSQL                             │
│    - Retourne EstablishmentResponse                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTP 201 Created
                       │ Body: {
                       │   "id": 1,
                       │   "name": "CHU Casablanca",
                       │   ...
                       │ }
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Frontend : ApiService reçoit la réponse                 │
│    - Status code : 201                                      │
│    - Body JSON                                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. Frontend : EstablishmentService                          │
│    - Décode JSON : jsonDecode(response.body)                │
│    - Crée objet : EstablishmentResponse.fromJson(data)      │
│    - Retourne l'objet                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. Frontend : Page affiche le résultat                     │
│    - Navigation vers ComprehensiveResultsPage               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Liste des Endpoints Disponibles

### **Authentification** (`/api/auth`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/auth/register` | Inscription |
| POST | `/api/auth/login` | Connexion |
| GET | `/api/auth/me` | Profil utilisateur |

### **Établissements** (`/api/establishments`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/establishments` | Liste des établissements |
| POST | `/api/establishments` | Créer un établissement |
| GET | `/api/establishments/{id}` | Détails d'un établissement |
| PUT | `/api/establishments/{id}` | Modifier un établissement |
| DELETE | `/api/establishments/{id}` | Supprimer un établissement |
| GET | `/api/establishments/{id}/comprehensive-results` | Résultats complets |
| GET | `/api/establishments/{id}/recommendations` | Recommandations |
| GET | `/api/establishments/{id}/savings` | Économies |
| GET | `/api/establishments/{id}/forecast` | Prévisions IA |
| GET | `/api/establishments/{id}/anomalies` | Anomalies |
| GET | `/api/establishments/{id}/recommendations/ml` | Recommandations ML |
| POST | `/api/establishments/{id}/simulate` | Simulation What-If |

### **Localisation** (`/api/location`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/location/irradiation` | Classe d'irradiation |
| GET | `/api/location/estimate-population` | Estimation population |

### **IA** (`/api/ai`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/ai/retrain` | Réentraîner le modèle |
| GET | `/api/ai/training/status` | Statut entraînement |

### **Public** (`/api/public`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/public/health` | Health check |

---

## 🔐 Authentification JWT

### **Comment ça fonctionne :**

1. **Login** : Frontend envoie email/password → Backend retourne token JWT
2. **Stockage** : Token stocké dans SharedPreferences
3. **Inclusion automatique** : ApiService ajoute `Authorization: Bearer <token>` dans tous les headers
4. **Validation** : Backend valide le token via `JwtAuthenticationFilter`

```dart
// ApiService._getHeaders()
static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  if (includeAuth) {
    final token = await _getToken(); // Récupère depuis SharedPreferences
    if (token != null) {
      headers['Authorization'] = 'Bearer $token'; // ← Ajout automatique
    }
  }
  
  return headers;
}
```

---

## 🎯 Est-ce Dynamique ou Statique ?

### **Backend (Statique)**
- ✅ **Endpoints définis statiquement** dans les contrôleurs avec annotations
- ✅ **URLs fixes** : `/api/establishments`, `/api/auth`, etc.
- ✅ **Méthodes HTTP fixes** : GET, POST, PUT, DELETE

### **Frontend (Dynamique)**
- ✅ **Appels dynamiques** : Endpoints passés en paramètre
- ✅ **URLs construites dynamiquement** : `baseUrl + endpoint`
- ✅ **Body dynamique** : Données encodées en JSON à la volée
- ✅ **Paramètres dynamiques** : IDs, query params, etc.

### **Exemple de Dynamisme :**

```dart
// Endpoint dynamique avec ID
final id = 123;
final response = await ApiService.get('/establishments/$id');

// Endpoint dynamique avec query params
final latitude = 31.6295;
final longitude = -7.9811;
final response = await ApiService.get(
  '/location/irradiation?latitude=$latitude&longitude=$longitude'
);

// Body dynamique
final request = EstablishmentRequest(
  name: userInput,  // ← Dynamique
  type: selectedType,  // ← Dynamique
  // ...
);
final response = await ApiService.post('/establishments', request.toJson());
```

---

## 💡 Points Importants pour la Présentation

### **À expliquer :**

1. **Architecture REST**
   - Backend expose des endpoints statiques
   - Frontend fait des appels dynamiques
   - Communication via HTTP/JSON

2. **Service centralisé (ApiService)**
   - Un seul point d'entrée pour tous les appels
   - Gestion automatique du JWT
   - Construction dynamique des URLs

3. **Services métier**
   - EstablishmentService, AuthService, etc.
   - Utilisent ApiService
   - Encapsulent la logique métier

4. **Sérialisation/Désérialisation**
   - `toJson()` : Objet → JSON
   - `fromJson()` : JSON → Objet
   - Type safety avec modèles Dart

5. **Authentification**
   - JWT stocké localement
   - Inclusion automatique dans headers
   - Validation côté backend

---

## 📝 Résumé

**Backend (Spring Boot) :**
- Endpoints définis avec annotations (`@GetMapping`, `@PostMapping`, etc.)
- URLs statiques mais paramètres dynamiques (`{id}`, query params)
- Retourne JSON automatiquement

**Frontend (Flutter) :**
- Appels dynamiques via `ApiService`
- URLs construites dynamiquement (`baseUrl + endpoint`)
- Body encodé en JSON dynamiquement
- Token JWT inclus automatiquement

**C'est donc un mélange :**
- ✅ **Endpoints statiques** côté backend (définis une fois)
- ✅ **Appels dynamiques** côté frontend (construits à la volée)

---

**Les REST API permettent une communication flexible et standardisée entre le frontend et le backend ! 🚀**

