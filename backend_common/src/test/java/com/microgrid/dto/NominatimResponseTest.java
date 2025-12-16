package com.microgrid.dto;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests pour le DTO NominatimResponse
 */
public class NominatimResponseTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    public void testParseNominatimResponse_WithPopulation() throws Exception {
        // Exemple de réponse Nominatim avec population
        String jsonResponse = """
            {
                "place_id": 123456789,
                "display_name": "Casablanca, Morocco",
                "address": {
                    "city": "Casablanca",
                    "state": "Casablanca-Settat",
                    "country": "Morocco",
                    "country_code": "ma"
                },
                "extratags": {
                    "population": "3500000",
                    "population:date": "2020"
                }
            }
            """;

        NominatimResponse response = objectMapper.readValue(jsonResponse, NominatimResponse.class);

        assertNotNull(response);
        assertEquals(123456789L, response.getPlaceId());
        assertEquals("Casablanca, Morocco", response.getDisplayName());
        assertNotNull(response.getAddress());
        assertEquals("Casablanca", response.getAddress().getCity());
        assertNotNull(response.getExtraTags());
        assertEquals("3500000", response.getExtraTags().getPopulation());
        
        // Test de l'extraction de la population
        Integer population = response.getPopulation();
        assertNotNull(population);
        assertEquals(3500000, population);
        
        // Test de l'extraction du nom de la ville
        String cityName = response.getCityName();
        assertEquals("Casablanca", cityName);
    }

    @Test
    public void testParseNominatimResponse_WithoutPopulation() throws Exception {
        // Exemple de réponse Nominatim sans population
        String jsonResponse = """
            {
                "place_id": 987654321,
                "display_name": "Small Village, Morocco",
                "address": {
                    "village": "Small Village",
                    "state": "Some Region",
                    "country": "Morocco",
                    "country_code": "ma"
                }
            }
            """;

        NominatimResponse response = objectMapper.readValue(jsonResponse, NominatimResponse.class);

        assertNotNull(response);
        assertNull(response.getExtraTags());
        
        // La population devrait être null
        Integer population = response.getPopulation();
        assertNull(population);
        
        // Le nom de la ville devrait être extrait depuis "village"
        String cityName = response.getCityName();
        assertEquals("Small Village", cityName);
    }

    @Test
    public void testParseNominatimResponse_PopulationWithCommas() throws Exception {
        // Test avec population contenant des virgules
        String jsonResponse = """
            {
                "extratags": {
                    "population": "1,234,567"
                }
            }
            """;

        NominatimResponse response = objectMapper.readValue(jsonResponse, NominatimResponse.class);

        Integer population = response.getPopulation();
        assertNotNull(population);
        assertEquals(1234567, population);
    }

    @Test
    public void testGetCityName_Priority() throws Exception {
        // Test de la priorité d'extraction du nom de ville
        String jsonResponse = """
            {
                "address": {
                    "city": "City",
                    "town": "Town",
                    "village": "Village",
                    "municipality": "Municipality"
                }
            }
            """;

        NominatimResponse response = objectMapper.readValue(jsonResponse, NominatimResponse.class);

        // "city" devrait avoir la priorité
        assertEquals("City", response.getCityName());
    }

    @Test
    public void testGetCityName_NoCity() throws Exception {
        // Test sans "city", devrait utiliser "town"
        String jsonResponse = """
            {
                "address": {
                    "town": "Town",
                    "village": "Village"
                }
            }
            """;

        NominatimResponse response = objectMapper.readValue(jsonResponse, NominatimResponse.class);

        assertEquals("Town", response.getCityName());
    }
}


