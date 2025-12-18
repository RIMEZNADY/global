# 📚 JUnit, Mockito et AssertJ : Différences et Utilisation

## 🎯 Résumé Rapide

| Outil | Rôle | Quand l'utiliser |
|-------|------|------------------|
| **JUnit 5** | Framework de test (structure, exécution) | **TOUJOURS** - Base de tous les tests |
| **Mockito** | Création de mocks (simuler dépendances) | Quand vous testez une classe qui dépend d'autres services |
| **AssertJ** | Assertions fluides et lisibles | **RECOMMANDÉ** - Remplace les assertions JUnit pour plus de clarté |

## 🔍 Différences Détaillées

### 1. JUnit 5 - Le Framework de Base

**Rôle :** Structure et exécution des tests

**Ce qu'il fait :**
- Définit la structure des tests (`@Test`, `@BeforeEach`, etc.)
- Exécute les tests
- Fournit des assertions de base (`assertEquals`, `assertTrue`, etc.)

**Exemple :**
```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

@Test
void testCalculROI() {
    // Arrange
    double investissement = 100000;
    double economieAnnuelle = 20000;
    
    // Act
    double roi = investissement / economieAnnuelle;
    
    // Assert (JUnit basique)
    assertEquals(5.0, roi);
    assertTrue(roi > 0);
}
```

---

### 2. Mockito - Simuler les Dépendances

**Rôle :** Créer des "mocks" (objets simulés) pour isoler le code testé

**Quand l'utiliser :**
- Votre classe dépend d'un service externe (API, base de données, autre service)
- Vous voulez tester votre logique SANS dépendre de services réels
- Vous voulez contrôler le comportement des dépendances

**Exemple concret dans votre projet :**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ComprehensiveResultsServiceTest {
    
    // Mock du service IA (on simule l'appel API)
    @Mock
    private AiMicroserviceClient aiClient;
    
    // Mock du repository (on simule la base de données)
    @Mock
    private EstablishmentRepository establishmentRepository;
    
    // La classe à tester (Mockito injecte automatiquement les mocks)
    @InjectMocks
    private ComprehensiveResultsService service;
    
    @Test
    void testCalculResultatsComplets() {
        // Arrange : On définit ce que les mocks doivent retourner
        Establishment etablissement = new Establishment();
        etablissement.setId(1L);
        
        when(establishmentRepository.findById(1L))
            .thenReturn(Optional.of(etablissement));
        
        when(aiClient.getPredictions(any()))
            .thenReturn(new PredictionResponse(1000.0, 500.0));
        
        // Act : On teste notre service
        ComprehensiveResults results = service.calculateResults(1L);
        
        // Assert : On vérifie les résultats
        assertNotNull(results);
        assertEquals(1000.0, results.getPredictedConsumption());
        
        // Vérifier que les méthodes ont été appelées
        verify(establishmentRepository).findById(1L);
        verify(aiClient).getPredictions(any());
    }
}
```

**Pourquoi Mockito est important :**
- ✅ Tests rapides (pas d'appels API réels)
- ✅ Tests isolés (pas de dépendance à la base de données)
- ✅ Contrôle total sur les scénarios (erreurs, valeurs limites, etc.)

---

### 3. AssertJ - Assertions Fluides et Lisibles

**Rôle :** Remplacer les assertions JUnit par des assertions plus lisibles

**Avantages :**
- Syntaxe fluide et naturelle
- Messages d'erreur plus clairs
- Plus de méthodes d'assertion

**Comparaison :**

```java
// ❌ AVEC JUnit (basique)
assertEquals(5.0, roi);
assertTrue(roi > 0);
assertNotNull(results);
assertTrue(results.getPredictedConsumption() > 0 && 
           results.getPredictedConsumption() < 10000);

// ✅ AVEC AssertJ (fluide et lisible)
assertThat(roi).isEqualTo(5.0);
assertThat(roi).isPositive();
assertThat(results).isNotNull();
assertThat(results.getPredictedConsumption())
    .isPositive()
    .isLessThan(10000);
```

**Exemple complet avec AssertJ :**

```java
import static org.assertj.core.api.Assertions.*;

@Test
void testResultatsComplets() {
    ComprehensiveResults results = service.calculateResults(1L);
    
    // Assertions fluides et lisibles
    assertThat(results)
        .isNotNull()
        .satisfies(r -> {
            assertThat(r.getPredictedConsumption())
                .isPositive()
                .isBetween(0.0, 100000.0);
            
            assertThat(r.getFinancialMetrics())
                .isNotNull()
                .extracting("roi", "paybackPeriod")
                .containsExactly(5.2, 4.8);
        });
    
    // Vérifier une liste
    assertThat(results.getRecommendations())
        .isNotEmpty()
        .hasSize(3)
        .extracting("type")
        .containsExactly("success", "warning", "info");
}
```

---

## 🤔 Faut-il Utiliser les 3 ?

### ✅ OUI, mais de manière progressive :

1. **JUnit 5** : **OBLIGATOIRE** - Base de tous les tests
2. **AssertJ** : **FORTEMENT RECOMMANDÉ** - Améliore la lisibilité
3. **Mockito** : **NÉCESSAIRE** pour les tests unitaires isolés

### 📊 Stratégie d'Adoption

#### Phase 1 : Début (Tests simples)
```java
// JUnit seul suffit pour les tests simples
@Test
void testCalculSimple() {
    double result = calculator.add(2, 3);
    assertEquals(5.0, result);
}
```

#### Phase 2 : Tests avec dépendances
```java
// Ajouter Mockito quand vous avez des dépendances
@ExtendWith(MockitoExtension.class)
class ServiceTest {
    @Mock
    private Dependency dependency;
    
    @Test
    void testAvecMock() {
        when(dependency.getValue()).thenReturn(10);
        // ...
    }
}
```

#### Phase 3 : Améliorer la lisibilité
```java
// Remplacer les assertions JUnit par AssertJ
assertThat(result)
    .isEqualTo(5.0)
    .isPositive();
```

---

## 💡 Exemple Complet : Test d'un Service Réel

Voici comment vous pourriez tester `ComprehensiveResultsService` avec les 3 outils :

```java
package com.microgrid.service;

import com.microgrid.model.Establishment;
import com.microgrid.repository.EstablishmentRepository;
import com.microgrid.client.AiMicroserviceClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)  // JUnit + Mockito
class ComprehensiveResultsServiceTest {
    
    @Mock
    private EstablishmentRepository establishmentRepository;
    
    @Mock
    private AiMicroserviceClient aiClient;
    
    @InjectMocks
    private ComprehensiveResultsService service;
    
    private Establishment testEstablishment;
    
    @BeforeEach  // JUnit : méthode exécutée avant chaque test
    void setUp() {
        testEstablishment = new Establishment();
        testEstablishment.setId(1L);
        testEstablishment.setMonthlyConsumption(50000.0);
    }
    
    @Test  // JUnit : marque la méthode comme test
    void testCalculateResults_Success() {
        // Arrange (Mockito : simuler les dépendances)
        when(establishmentRepository.findById(1L))
            .thenReturn(Optional.of(testEstablishment));
        
        when(aiClient.getPredictions(any()))
            .thenReturn(new PredictionResponse(45000.0, 10000.0));
        
        // Act
        ComprehensiveResults results = service.calculateResults(1L);
        
        // Assert (AssertJ : assertions fluides)
        assertThat(results)
            .isNotNull()
            .satisfies(r -> {
                assertThat(r.getPredictedConsumption())
                    .isEqualTo(45000.0)
                    .isPositive();
                
                assertThat(r.getFinancialMetrics().getRoi())
                    .isBetween(0.0, 20.0);
            });
        
        // Vérifier les interactions (Mockito)
        verify(establishmentRepository).findById(1L);
        verify(aiClient).getPredictions(any());
    }
    
    @Test
    void testCalculateResults_EstablishmentNotFound() {
        // Arrange
        when(establishmentRepository.findById(999L))
            .thenReturn(Optional.empty());
        
        // Act & Assert
        assertThatThrownBy(() -> service.calculateResults(999L))
            .isInstanceOf(NotFoundException.class)
            .hasMessageContaining("Establishment not found");
        
        verify(establishmentRepository).findById(999L);
        verify(aiClient, never()).getPredictions(any());
    }
}
```

---

## 📝 Résumé pour votre PAQP

### Dans votre document, vous pouvez écrire :

**Technologies :**
- **JUnit 5** : Framework de test (structure, exécution)
- **Mockito** : Mocking framework (isolation des dépendances)
- **AssertJ** : Assertions fluides (amélioration de la lisibilité)

**Justification :**
- JUnit 5 : Standard pour les tests Java/Spring Boot
- Mockito : Nécessaire pour isoler les tests unitaires (éviter les appels API/DB réels)
- AssertJ : Améliore la maintenabilité et la lisibilité des tests

**Utilisation :**
- Tests simples : JUnit seul
- Tests avec dépendances : JUnit + Mockito
- Tous les tests : JUnit + Mockito + AssertJ (recommandé)

---

## 🎓 Conclusion

**OUI, utilisez les 3 !** Ils sont complémentaires :
- **JUnit 5** = Le moteur (obligatoire)
- **Mockito** = L'isolation (nécessaire pour tests unitaires)
- **AssertJ** = La clarté (fortement recommandé)

Ils sont déjà inclus dans `spring-boot-starter-test`, donc pas besoin d'ajouter de dépendances supplémentaires !


