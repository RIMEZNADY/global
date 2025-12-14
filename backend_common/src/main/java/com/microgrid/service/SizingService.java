package com.microgrid.service;

import com.microgrid.model.Establishment;
import com.microgrid.model.MoroccanCity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * Service pour calculer les recommandations de dimensionnement PV et batterie
 */
@Service
public class SizingService {

    @Autowired
    private PvCalculationService pvCalculationService;

    @Autowired
    private ConsumptionEstimationService consumptionEstimationService;

    @Autowired
    private MeteoDataService meteoDataService;

    // Constantes pour le dimensionnement
    private static final double PANEL_EFFICIENCY = 0.20;
    private static final double PERFORMANCE_FACTOR = 0.80;
    private static final double AUTONOMY_DAYS = 2.0; // 2 jours d'autonomie recommandés
    private static final double SAFETY_FACTOR = 1.3; // Facteur de sécurité 30%

    /**
     * Calcule la puissance PV recommandée selon la consommation mensuelle et la classe d'irradiation
     * 
     * @param monthlyConsumptionKwh Consommation mensuelle en kWh
     * @param irradiationClass Classe d'irradiation
     * @return Puissance PV recommandée en kWc
     */
    public double calculateRecommendedPvPower(double monthlyConsumptionKwh, MoroccanCity.IrradiationClass irradiationClass) {
        // Consommation quotidienne moyenne
        double dailyConsumption = monthlyConsumptionKwh / 30.0;
        
        // Irradiance moyenne selon la classe
        double averageIrradiance = meteoDataService.getAverageIrradiance(irradiationClass);
        
        // Production nécessaire par jour pour couvrir la consommation
        // Formule: Consommation_jour / (Irradiance × Efficacité × Facteur_performance)
        double requiredDailyProduction = dailyConsumption;
        double pvPowerKwc = requiredDailyProduction / (averageIrradiance * PANEL_EFFICIENCY * PERFORMANCE_FACTOR);
        
        // Ajouter un facteur de sécurité pour les jours moins ensoleillés
        return pvPowerKwc * SAFETY_FACTOR;
    }

    /**
     * Calcule la surface PV recommandée
     * 
     * @param monthlyConsumptionKwh Consommation mensuelle en kWh
     * @param irradiationClass Classe d'irradiation
     * @return Surface PV recommandée en m²
     */
    public double calculateRecommendedPvSurface(double monthlyConsumptionKwh, MoroccanCity.IrradiationClass irradiationClass) {
        double pvPowerKwc = calculateRecommendedPvPower(monthlyConsumptionKwh, irradiationClass);
        return pvCalculationService.calculateRequiredSurface(pvPowerKwc);
    }

    /**
     * Calcule la capacité batterie recommandée selon la consommation quotidienne
     * 
     * @param dailyConsumptionKwh Consommation quotidienne en kWh/jour
     * @return Capacité batterie recommandée en kWh
     */
    public double calculateRecommendedBatteryCapacity(double dailyConsumptionKwh) {
        // Capacité = Consommation_journée × Jours_autonomie × Facteur_sécurité
        return dailyConsumptionKwh * AUTONOMY_DAYS * SAFETY_FACTOR;
    }

    /**
     * Calcule la capacité batterie recommandée selon la consommation mensuelle
     * 
     * @param monthlyConsumptionKwh Consommation mensuelle en kWh
     * @return Capacité batterie recommandée en kWh
     */
    public double calculateRecommendedBatteryCapacityFromMonthly(double monthlyConsumptionKwh) {
        double dailyConsumption = monthlyConsumptionKwh / 30.0;
        return calculateRecommendedBatteryCapacity(dailyConsumption);
    }

    /**
     * Calcule le pourcentage d'autonomie énergétique possible avec une installation PV donnée
     * 
     * @param pvSurfaceM2 Surface PV installée en m²
     * @param monthlyConsumptionKwh Consommation mensuelle en kWh
     * @param irradiationClass Classe d'irradiation
     * @return Pourcentage d'autonomie (0-100)
     */
    public double calculateEnergyAutonomy(double pvSurfaceM2, double monthlyConsumptionKwh, MoroccanCity.IrradiationClass irradiationClass) {
        double monthlyPvProduction = pvCalculationService.calculateMonthlyPvProduction(pvSurfaceM2, irradiationClass);
        
        if (monthlyConsumptionKwh == 0) {
            return 0.0;
        }
        
        double autonomy = (monthlyPvProduction / monthlyConsumptionKwh) * 100.0;
        return Math.min(autonomy, 100.0); // Limiter à 100%
    }

    /**
     * Calcule les économies annuelles potentielles
     * 
     * @param monthlyConsumptionKwh Consommation mensuelle en kWh
     * @param autonomyPercentage Pourcentage d'autonomie
     * @param electricityPriceDhPerKwh Prix de l'électricité en DH/kWh
     * @return Économies annuelles en DH
     */
    public double calculateAnnualSavings(double monthlyConsumptionKwh, double autonomyPercentage, double electricityPriceDhPerKwh) {
        double annualConsumption = monthlyConsumptionKwh * 12;
        double energyFromPv = annualConsumption * (autonomyPercentage / 100.0);
        return energyFromPv * electricityPriceDhPerKwh;
    }

    /**
     * Calcule le ROI (Retour sur Investissement) en années
     * 
     * @param installationCostDh Coût d'installation en DH
     * @param annualSavingsDh Économies annuelles en DH
     * @return ROI en années
     */
    public double calculateROI(double installationCostDh, double annualSavingsDh) {
        if (annualSavingsDh == 0) {
            return Double.MAX_VALUE; // Pas de retour sur investissement
        }
        return installationCostDh / annualSavingsDh;
    }
}


