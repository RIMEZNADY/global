package com.microgrid.service;

import com.microgrid.model.Establishment.IrradiationClass;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests pour LocationService, notamment l'estimation de population avec Nominatim
 */
@SpringBootTest
@ActiveProfiles("test")
public class LocationServiceTest {

    @Autowired
    private LocationService locationService;

    /**
     * Test de l'estimation de population pour Casablanca (grande ville)
     * Coordonnées: 33.5731, -7.5898
     */
    @Test
    public void testEstimatePopulation_Casablanca() {
        Double latitude = 33.5731;
        Double longitude = -7.5898;
        String establishmentType = "CHU";
        Integer numberOfBeds = 500;

        Integer population = locationService.estimatePopulation(
            latitude, longitude, establishmentType, numberOfBeds
        );

        assertNotNull(population, "La population ne doit pas être null");
        assertTrue(population >= 10000, "La population doit être >= 10000");
        assertTrue(population <= 5000000, "La population doit être <= 5000000");
        
        // Casablanca devrait avoir une grande population (plusieurs millions)
        // Si Nominatim fonctionne, on devrait avoir une valeur réaliste
        System.out.println("Population estimée pour Casablanca: " + population);
    }

    /**
     * Test de l'estimation de population pour Rabat (ville moyenne)
     * Coordonnées: 34.0209, -6.8416
     */
    @Test
    public void testEstimatePopulation_Rabat() {
        Double latitude = 34.0209;
        Double longitude = -6.8416;
        String establishmentType = "HOPITAL_REGIONAL";
        Integer numberOfBeds = 300;

        Integer population = locationService.estimatePopulation(
            latitude, longitude, establishmentType, numberOfBeds
        );

        assertNotNull(population);
        assertTrue(population >= 10000);
        assertTrue(population <= 5000000);
        
        System.out.println("Population estimée pour Rabat: " + population);
    }

    /**
     * Test de l'estimation de population pour une petite ville
     * Coordonnées: 34.2611, -6.5802 (Kénitra)
     */
    @Test
    public void testEstimatePopulation_SmallCity() {
        Double latitude = 34.2611;
        Double longitude = -6.5802;
        String establishmentType = "CENTRE_SANTE_PRIMAIRE";
        Integer numberOfBeds = 50;

        Integer population = locationService.estimatePopulation(
            latitude, longitude, establishmentType, numberOfBeds
        );

        assertNotNull(population);
        assertTrue(population >= 10000);
        assertTrue(population <= 5000000);
        
        System.out.println("Population estimée pour Kénitra: " + population);
    }

    /**
     * Test avec des coordonnées null
     */
    @Test
    public void testEstimatePopulation_NullCoordinates() {
        Integer population = locationService.estimatePopulation(
            null, null, "CHU", 100
        );

        assertEquals(50000, population, "Devrait retourner la valeur par défaut (50000)");
    }

    /**
     * Test de la détermination de la classe d'irradiation
     */
    @Test
    public void testDetermineIrradiationClass() {
        // Casablanca (Zone C)
        IrradiationClass casablanca = locationService.determineIrradiationClass(33.5731, -7.5898);
        assertNotNull(casablanca);
        
        // Rabat (Zone D)
        IrradiationClass rabat = locationService.determineIrradiationClass(34.0209, -6.8416);
        assertNotNull(rabat);
        
        System.out.println("Classe d'irradiation Casablanca: " + casablanca);
        System.out.println("Classe d'irradiation Rabat: " + rabat);
    }

    /**
     * Test avec différents types d'établissements
     */
    @Test
    public void testEstimatePopulation_DifferentEstablishmentTypes() {
        Double latitude = 33.5731; // Casablanca
        Double longitude = -7.5898;
        Integer numberOfBeds = 200;

        // Test CHU (devrait donner une population plus élevée)
        Integer populationCHU = locationService.estimatePopulation(
            latitude, longitude, "CHU", numberOfBeds
        );

        // Test Centre de Santé Primaire (devrait donner une population plus faible)
        Integer populationCentre = locationService.estimatePopulation(
            latitude, longitude, "CENTRE_SANTE_PRIMAIRE", numberOfBeds
        );

        assertNotNull(populationCHU);
        assertNotNull(populationCentre);
        
        // CHU devrait généralement avoir une estimation plus élevée que Centre de Santé
        // (sauf si Nominatim retourne la même valeur réelle)
        System.out.println("Population CHU: " + populationCHU);
        System.out.println("Population Centre de Santé: " + populationCentre);
    }
}
