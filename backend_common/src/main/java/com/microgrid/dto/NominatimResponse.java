package com.microgrid.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

/**
 * DTO pour la réponse de l'API Nominatim (OpenStreetMap)
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class NominatimResponse {
    
    @JsonProperty("place_id")
    private Long placeId;
    
    @JsonProperty("display_name")
    private String displayName;
    
    @JsonProperty("address")
    private Address address;
    
    @JsonProperty("extratags")
    private ExtraTags extraTags;
    
    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Address {
        private String city;
        private String town;
        private String village;
        private String municipality;
        private String county;
        private String state;
        private String country;
        @JsonProperty("country_code")
        private String countryCode;
    }
    
    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ExtraTags {
        private String population;
        @JsonProperty("population:date")
        private String populationDate;
    }
    
    /**
     * Extrait la population depuis les extraTags ou l'adresse
     * @return Population en Integer, ou null si non disponible
     */
    public Integer getPopulation() {
        if (extraTags != null && extraTags.getPopulation() != null) {
            try {
                // La population peut être au format "123456" ou "123,456"
                String popStr = extraTags.getPopulation().replace(",", "").trim();
                return Integer.parseInt(popStr);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }
    
    /**
     * Obtient le nom de la ville depuis l'adresse
     */
    public String getCityName() {
        if (address == null) {
            return null;
        }
        if (address.getCity() != null) {
            return address.getCity();
        }
        if (address.getTown() != null) {
            return address.getTown();
        }
        if (address.getVillage() != null) {
            return address.getVillage();
        }
        if (address.getMunicipality() != null) {
            return address.getMunicipality();
        }
        return null;
    }
}





