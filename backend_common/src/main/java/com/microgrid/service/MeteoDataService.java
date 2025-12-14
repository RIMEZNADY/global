package com.microgrid.service;

import com.microgrid.model.MoroccanCity;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

/**
 * Service pour mapper les classes d'irradiation aux fichiers de données météorologiques
 */
@Service
public class MeteoDataService {

    /**
     * Mappe la classe d'irradiation vers le nom du fichier de données météo
     * 
     * @param irradiationClass Classe d'irradiation (A, B, C, D)
     * @return Nom du fichier CSV correspondant
     */
    public String getMeteoFileName(MoroccanCity.IrradiationClass irradiationClass) {
        Map<MoroccanCity.IrradiationClass, String> fileMap = new HashMap<>();
        fileMap.put(MoroccanCity.IrradiationClass.A, "zone_a_sahara_meteo_2024_6h.csv");
        fileMap.put(MoroccanCity.IrradiationClass.B, "zone_b_centre_meteo_2024_6h.csv");
        fileMap.put(MoroccanCity.IrradiationClass.C, "casablanca_meteo_2024_6h.csv");
        fileMap.put(MoroccanCity.IrradiationClass.D, "zone_d_rif_meteo_2024_6h.csv");
        
        return fileMap.getOrDefault(irradiationClass, "casablanca_meteo_2024_6h.csv");
    }

    /**
     * Mappe la classe d'irradiation vers le nom du fichier de données PV
     * 
     * @param irradiationClass Classe d'irradiation (A, B, C, D)
     * @return Nom du fichier CSV correspondant
     */
    public String getPvFileName(MoroccanCity.IrradiationClass irradiationClass) {
        Map<MoroccanCity.IrradiationClass, String> fileMap = new HashMap<>();
        fileMap.put(MoroccanCity.IrradiationClass.A, "zone_a_sahara_pv_2024_6h.csv");
        fileMap.put(MoroccanCity.IrradiationClass.B, "zone_b_centre_pv_2024_6h.csv");
        fileMap.put(MoroccanCity.IrradiationClass.C, "casablanca_pv_2024_6h.csv");
        fileMap.put(MoroccanCity.IrradiationClass.D, "zone_d_rif_pv_2024_6h.csv");
        
        return fileMap.getOrDefault(irradiationClass, "casablanca_pv_2024_6h.csv");
    }

    /**
     * Obtient les statistiques moyennes d'irradiance par classe
     * 
     * @param irradiationClass Classe d'irradiation
     * @return Irradiance moyenne en kWh/m²/jour
     */
    public double getAverageIrradiance(MoroccanCity.IrradiationClass irradiationClass) {
        Map<MoroccanCity.IrradiationClass, Double> avgIrradiance = new HashMap<>();
        avgIrradiance.put(MoroccanCity.IrradiationClass.A, 6.5); // 6-7 kWh/m²/jour
        avgIrradiance.put(MoroccanCity.IrradiationClass.B, 5.5); // 5-6 kWh/m²/jour
        avgIrradiance.put(MoroccanCity.IrradiationClass.C, 4.5); // 4-5 kWh/m²/jour
        avgIrradiance.put(MoroccanCity.IrradiationClass.D, 3.5); // 3-4 kWh/m²/jour
        
        return avgIrradiance.getOrDefault(irradiationClass, 4.5);
    }

    /**
     * Obtient la description de la zone d'irradiation
     * 
     * @param irradiationClass Classe d'irradiation
     * @return Description de la zone
     */
    public String getZoneDescription(MoroccanCity.IrradiationClass irradiationClass) {
        Map<MoroccanCity.IrradiationClass, String> descriptions = new HashMap<>();
        descriptions.put(MoroccanCity.IrradiationClass.A, "Zone à très fort rayonnement (Sud-Est, Sahara) - 6-7 kWh/m²/jour");
        descriptions.put(MoroccanCity.IrradiationClass.B, "Zone à fort rayonnement (Centre, Sud) - 5-6 kWh/m²/jour");
        descriptions.put(MoroccanCity.IrradiationClass.C, "Zone à rayonnement moyen (Nord, Côtes - Casablanca) - 4-5 kWh/m²/jour");
        descriptions.put(MoroccanCity.IrradiationClass.D, "Zone à rayonnement modéré (Rif, Hautes altitudes) - 3-4 kWh/m²/jour");
        
        return descriptions.getOrDefault(irradiationClass, "Zone non définie");
    }
}


