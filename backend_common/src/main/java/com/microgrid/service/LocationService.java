package com.microgrid.service;

import com.microgrid.model.Establishment.IrradiationClass;
import com.microgrid.model.MoroccanCity;
import com.microgrid.repository.MoroccanCityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class LocationService {
    
    @Autowired
    private MoroccanCityRepository cityRepository;
    
    /**
     * Détermine la classe d'irradiation solaire selon les coordonnées GPS
     * en trouvant la ville marocaine la plus proche
     */
    public IrradiationClass determineIrradiationClass(Double latitude, Double longitude) {
        if (latitude == null || longitude == null) {
            return IrradiationClass.C; // Par défaut (Casablanca)
        }
        
        Optional<MoroccanCity> nearestCity = cityRepository.findNearestCity(latitude, longitude);
        
        if (nearestCity.isPresent()) {
            // Convertir l'enum de MoroccanCity vers Establishment
            return convertIrradiationClass(nearestCity.get().getIrradiationClass());
        }
        
        // Si aucune ville trouvée, déterminer selon les coordonnées
        return determineIrradiationByCoordinates(latitude, longitude);
    }
    
    /**
     * Convertit l'enum IrradiationClass de MoroccanCity vers Establishment
     */
    private IrradiationClass convertIrradiationClass(MoroccanCity.IrradiationClass cityClass) {
        return switch (cityClass) {
            case A -> IrradiationClass.A;
            case B -> IrradiationClass.B;
            case C -> IrradiationClass.C;
            case D -> IrradiationClass.D;
        };
    }
    
    /**
     * Détermine la classe d'irradiation selon les coordonnées GPS
     * (méthode de fallback si aucune ville n'est trouvée)
     */
    private IrradiationClass determineIrradiationByCoordinates(Double latitude, Double longitude) {
        // Zone A: Sud-Est et Sahara (latitude < 30°)
        if (latitude < 30.0) {
            return IrradiationClass.A;
        }
        // Zone B: Centre et Sud (30° - 32°)
        else if (latitude < 32.0) {
            return IrradiationClass.B;
        }
        // Zone C: Nord et Côtes (32° - 34°)
        else if (latitude < 34.0) {
            return IrradiationClass.C;
        }
        // Zone D: Rif et Hautes altitudes (latitude >= 34°)
        else {
            return IrradiationClass.D;
        }
    }
    
    /**
     * Obtient la ville la plus proche d'un point GPS
     */
    public Optional<MoroccanCity> getNearestCity(Double latitude, Double longitude) {
        if (latitude == null || longitude == null) {
            return Optional.empty();
        }
        return cityRepository.findNearestCity(latitude, longitude);
    }
}


