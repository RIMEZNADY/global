package com.microgrid.service;

import org.springframework.stereotype.Service;

/**
 * Service pour valider les résultats de l'IA
 */
@Service
public class AiResultValidator {

    // Plages raisonnables pour la consommation (kWh)
    private static final double MIN_CONSUMPTION_KWH = 0.0;
    private static final double MAX_CONSUMPTION_KWH = 10000.0; // 10 MWh par pas de 6h (très élevé)

    // Plages raisonnables pour le SOC (kWh)
    private static final double MIN_SOC_KWH = 0.0;
    
    // Plages raisonnables pour l'import réseau (kWh)
    private static final double MIN_GRID_IMPORT_KWH = 0.0;
    private static final double MAX_GRID_IMPORT_KWH = 5000.0; // 5 MWh par pas de 6h

    // Plages raisonnables pour la charge/décharge batterie (kWh)
    private static final double MIN_BATTERY_KWH = 0.0;
    private static final double MAX_BATTERY_CHARGE_KWH = 2000.0; // 2 MWh par pas de 6h
    private static final double MAX_BATTERY_DISCHARGE_KWH = 2000.0; // 2 MWh par pas de 6h

    /**
     * Valide une prédiction de consommation
     * 
     * @param predictedConsumption Prédiction en kWh
     * @param dailyConsumption Consommation quotidienne moyenne (pour validation relative)
     * @return true si valide, false sinon
     */
    public boolean isValidConsumption(double predictedConsumption, double dailyConsumption) {
        if (predictedConsumption < MIN_CONSUMPTION_KWH) {
            return false;
        }
        
        // La consommation par pas de 6h ne devrait pas dépasser 2x la consommation quotidienne
        // (cas extrême de pic de consommation)
        double maxReasonableConsumption = dailyConsumption * 2.0;
        if (predictedConsumption > Math.max(maxReasonableConsumption, MAX_CONSUMPTION_KWH)) {
            return false;
        }
        
        return true;
    }

    /**
     * Valide un SOC (State of Charge)
     * 
     * @param soc SOC en kWh
     * @param batteryCapacity Capacité de la batterie en kWh
     * @return true si valide, false sinon
     */
    public boolean isValidSoc(double soc, double batteryCapacity) {
        if (soc < MIN_SOC_KWH) {
            return false;
        }
        
        // Le SOC ne devrait pas dépasser la capacité de la batterie
        if (soc > batteryCapacity * 1.05) { // 5% de marge pour erreurs d'arrondi
            return false;
        }
        
        return true;
    }

    /**
     * Valide un résultat d'optimisation
     * 
     * @param gridImport Import réseau en kWh
     * @param batteryCharge Charge batterie en kWh
     * @param batteryDischarge Décharge batterie en kWh
     * @param socNext Nouveau SOC en kWh
     * @param batteryCapacity Capacité de la batterie en kWh
     * @return true si valide, false sinon
     */
    public boolean isValidOptimization(
            double gridImport,
            double batteryCharge,
            double batteryDischarge,
            double socNext,
            double batteryCapacity) {
        
        // Valider import réseau
        if (gridImport < MIN_GRID_IMPORT_KWH || gridImport > MAX_GRID_IMPORT_KWH) {
            return false;
        }
        
        // Valider charge batterie
        if (batteryCharge < MIN_BATTERY_KWH || batteryCharge > MAX_BATTERY_CHARGE_KWH) {
            return false;
        }
        
        // Valider décharge batterie
        if (batteryDischarge < MIN_BATTERY_KWH || batteryDischarge > MAX_BATTERY_DISCHARGE_KWH) {
            return false;
        }
        
        // Valider SOC
        if (!isValidSoc(socNext, batteryCapacity)) {
            return false;
        }
        
        // Cohérence : charge et décharge ne peuvent pas être > 0 en même temps
        if (batteryCharge > 0.01 && batteryDischarge > 0.01) {
            return false;
        }
        
        return true;
    }

    /**
     * Corrige une prédiction de consommation si elle est invalide
     * 
     * @param predictedConsumption Prédiction en kWh
     * @param dailyConsumption Consommation quotidienne moyenne
     * @return Consommation corrigée
     */
    public double correctConsumption(double predictedConsumption, double dailyConsumption) {
        if (predictedConsumption < MIN_CONSUMPTION_KWH) {
            return dailyConsumption / 4.0; // Moyenne par pas de 6h
        }
        
        double maxReasonableConsumption = dailyConsumption * 2.0;
        if (predictedConsumption > Math.max(maxReasonableConsumption, MAX_CONSUMPTION_KWH)) {
            return Math.min(maxReasonableConsumption, MAX_CONSUMPTION_KWH);
        }
        
        return predictedConsumption;
    }

    /**
     * Corrige un SOC si invalide
     * 
     * @param soc SOC en kWh
     * @param batteryCapacity Capacité de la batterie en kWh
     * @return SOC corrigé
     */
    public double correctSoc(double soc, double batteryCapacity) {
        if (soc < MIN_SOC_KWH) {
            return batteryCapacity * 0.15; // SOC minimum (15%)
        }
        
        if (soc > batteryCapacity * 1.05) {
            return batteryCapacity * 0.95; // SOC maximum (95%)
        }
        
        return Math.max(MIN_SOC_KWH, Math.min(soc, batteryCapacity));
    }
}


