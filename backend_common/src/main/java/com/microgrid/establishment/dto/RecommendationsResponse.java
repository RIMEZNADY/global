package com.microgrid.establishment.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RecommendationsResponse {
    
    private double recommendedPvPowerKwc;
    private double recommendedPvSurfaceM2;
    private double recommendedBatteryCapacityKwh;
    private double estimatedEnergyAutonomy;
    private double estimatedAnnualSavings;
    private double estimatedROI;
    private String description;
}


