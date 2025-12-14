package com.microgrid.service;

import com.microgrid.model.Establishment;
import com.microgrid.model.MoroccanCity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * Service pour calculer la production PV selon la surface, l'irradiance et la classe d'irradiation
 */
@Service
public class PvCalculationService {

    @Autowired
    private MeteoDataService meteoDataService;

    // Constantes pour le calcul PV
    private static final double PANEL_EFFICIENCY = 0.20; // 20% efficacité panneau
    private static final double PERFORMANCE_FACTOR = 0.80; // 80% facteur de performance (pertes système)
    private static final double PANEL_POWER_PER_M2 = 0.2; // 200W par m² (1 kWc = 5 m²)

    /**
     * Calcule la production PV quotidienne moyenne selon la surface et la classe d'irradiation
     * 
     * @param surfaceM2 Surface installable en m²
     * @param irradiationClass Classe d'irradiation (A, B, C, D)
     * @return Production PV quotidienne moyenne en kWh/jour
     */
    public double calculateDailyPvProduction(double surfaceM2, MoroccanCity.IrradiationClass irradiationClass) {
        double averageIrradiance = meteoDataService.getAverageIrradiance(irradiationClass);
        
        // Formule: Surface × Irradiance × Efficacité × Facteur_performance
        return surfaceM2 * averageIrradiance * PANEL_EFFICIENCY * PERFORMANCE_FACTOR;
    }

    /**
     * Calcule la production PV pour une période donnée
     * 
     * @param surfaceM2 Surface installable en m²
     * @param irradiationClass Classe d'irradiation
     * @param days Nombre de jours
     * @return Production PV totale en kWh
     */
    public double calculatePvProductionForPeriod(double surfaceM2, MoroccanCity.IrradiationClass irradiationClass, int days) {
        return calculateDailyPvProduction(surfaceM2, irradiationClass) * days;
    }

    /**
     * Calcule la puissance PV installée (kWc) selon la surface
     * 
     * @param surfaceM2 Surface installable en m²
     * @return Puissance PV en kWc
     */
    public double calculatePvPower(double surfaceM2) {
        // 1 kWc = 5 m² (panneau 200W/m²)
        return surfaceM2 * PANEL_POWER_PER_M2;
    }

    /**
     * Calcule la surface nécessaire pour une puissance PV donnée
     * 
     * @param powerKwc Puissance PV souhaitée en kWc
     * @return Surface nécessaire en m²
     */
    public double calculateRequiredSurface(double powerKwc) {
        return powerKwc / PANEL_POWER_PER_M2;
    }

    /**
     * Calcule la production PV horaire selon l'irradiance instantanée
     * 
     * @param surfaceM2 Surface installable en m²
     * @param irradianceKwhM2 Irradiance instantanée en kWh/m²
     * @return Production PV en kWh pour cette période
     */
    public double calculatePvProductionFromIrradiance(double surfaceM2, double irradianceKwhM2) {
        return surfaceM2 * irradianceKwhM2 * PANEL_EFFICIENCY * PERFORMANCE_FACTOR;
    }

    /**
     * Calcule la production PV mensuelle moyenne
     * 
     * @param surfaceM2 Surface installable en m²
     * @param irradiationClass Classe d'irradiation
     * @return Production PV mensuelle moyenne en kWh/mois
     */
    public double calculateMonthlyPvProduction(double surfaceM2, MoroccanCity.IrradiationClass irradiationClass) {
        return calculateDailyPvProduction(surfaceM2, irradiationClass) * 30;
    }
}


