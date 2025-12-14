package com.microgrid.service;

import com.microgrid.model.Establishment;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

/**
 * Service pour estimer la consommation énergétique selon le type d'établissement et le nombre de lits
 */
@Service
public class ConsumptionEstimationService {

    // Ratios de consommation par type d'établissement (kWh/lit/jour)
    private static final Map<Establishment.EstablishmentType, ConsumptionRatios> CONSUMPTION_RATIOS = new HashMap<>();

    static {
        // CHU
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.CHU, 
            new ConsumptionRatios(20.0, 0.60, 0.40)); // 15-25 kWh/lit/jour, 60% critique, 40% non-critique
        
        // Hôpitaux
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.HOPITAL_REGIONAL, 
            new ConsumptionRatios(16.0, 0.55, 0.45)); // 12-20 kWh/lit/jour
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.HOPITAL_PROVINCIAL, 
            new ConsumptionRatios(14.0, 0.50, 0.50)); // 10-18 kWh/lit/jour
        
        // Centres spécialisés
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.CENTRE_REGIONAL_ONCOLOGIE, 
            new ConsumptionRatios(18.0, 0.65, 0.35));
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.CENTRE_HEMODIALYSE, 
            new ConsumptionRatios(22.0, 0.70, 0.30));
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.CENTRE_REEDUCATION, 
            new ConsumptionRatios(12.0, 0.45, 0.55));
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.CENTRE_ADDICTOLOGIE, 
            new ConsumptionRatios(10.0, 0.40, 0.60));
        
        // Urgences
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.UMH, 
            new ConsumptionRatios(15.0, 0.60, 0.40));
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.UMP, 
            new ConsumptionRatios(12.0, 0.50, 0.50));
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.UPH, 
            new ConsumptionRatios(10.0, 0.45, 0.55));
        
        // Soins primaires
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.CENTRE_SANTE_PRIMAIRE, 
            new ConsumptionRatios(7.5, 0.40, 0.60)); // 5-10 kWh/lit/jour
        
        // Privé
        CONSUMPTION_RATIOS.put(Establishment.EstablishmentType.CLINIQUE_PRIVEE, 
            new ConsumptionRatios(11.5, 0.45, 0.55)); // 8-15 kWh/lit/jour
    }

    private static class ConsumptionRatios {
        final double kwhPerBedPerDay;
        final double criticalRatio;
        final double nonCriticalRatio;

        ConsumptionRatios(double kwhPerBedPerDay, double criticalRatio, double nonCriticalRatio) {
            this.kwhPerBedPerDay = kwhPerBedPerDay;
            this.criticalRatio = criticalRatio;
            this.nonCriticalRatio = nonCriticalRatio;
        }
    }

    /**
     * Estime la consommation quotidienne totale selon le type d'établissement et le nombre de lits
     * 
     * @param type Type d'établissement
     * @param numberOfBeds Nombre de lits
     * @return Consommation quotidienne en kWh/jour
     */
    public double estimateDailyConsumption(Establishment.EstablishmentType type, int numberOfBeds) {
        ConsumptionRatios ratios = CONSUMPTION_RATIOS.getOrDefault(type, 
            new ConsumptionRatios(12.0, 0.50, 0.50)); // Par défaut
        
        return ratios.kwhPerBedPerDay * numberOfBeds;
    }

    /**
     * Estime la consommation critique quotidienne
     * 
     * @param type Type d'établissement
     * @param numberOfBeds Nombre de lits
     * @return Consommation critique quotidienne en kWh/jour
     */
    public double estimateDailyCriticalConsumption(Establishment.EstablishmentType type, int numberOfBeds) {
        double dailyTotal = estimateDailyConsumption(type, numberOfBeds);
        ConsumptionRatios ratios = CONSUMPTION_RATIOS.getOrDefault(type, 
            new ConsumptionRatios(12.0, 0.50, 0.50)); // Par défaut
        
        return dailyTotal * ratios.criticalRatio;
    }

    /**
     * Estime la consommation non-critique quotidienne
     * 
     * @param type Type d'établissement
     * @param numberOfBeds Nombre de lits
     * @return Consommation non-critique quotidienne en kWh/jour
     */
    public double estimateDailyNonCriticalConsumption(Establishment.EstablishmentType type, int numberOfBeds) {
        double dailyTotal = estimateDailyConsumption(type, numberOfBeds);
        ConsumptionRatios ratios = CONSUMPTION_RATIOS.getOrDefault(type, 
            new ConsumptionRatios(12.0, 0.50, 0.50)); // Par défaut
        
        return dailyTotal * ratios.nonCriticalRatio;
    }

    /**
     * Estime la consommation mensuelle
     * 
     * @param type Type d'établissement
     * @param numberOfBeds Nombre de lits
     * @return Consommation mensuelle en kWh/mois
     */
    public double estimateMonthlyConsumption(Establishment.EstablishmentType type, int numberOfBeds) {
        return estimateDailyConsumption(type, numberOfBeds) * 30;
    }

    /**
     * Estime le nombre de patients selon le nombre de lits (taux d'occupation moyen)
     * 
     * @param numberOfBeds Nombre de lits
     * @return Nombre estimé de patients
     */
    public double estimatePatients(int numberOfBeds) {
        // Taux d'occupation moyen: 75-85% selon le type
        // On utilise 80% comme moyenne
        return numberOfBeds * 0.80;
    }
}

