package com.microgrid.establishment.dto;

import com.microgrid.model.Establishment;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

@Data
public class EstablishmentRequest {
    
    @NotBlank(message = "Le nom de l'établissement est requis")
    private String name;
    
    @NotNull(message = "Le type d'établissement est requis")
    private Establishment.EstablishmentType type;
    
    @NotNull(message = "Le nombre de lits est requis")
    @Positive(message = "Le nombre de lits doit être positif")
    private Integer numberOfBeds;
    
    private String address;
    
    private Double latitude;
    
    private Double longitude;
    
    private Establishment.IrradiationClass irradiationClass;
    
    // Surface et énergie (Cas 1 - EXISTANT)
    private Double installableSurfaceM2;
    
    private Double nonCriticalSurfaceM2;
    
    private Double monthlyConsumptionKwh;
    
    private Boolean existingPvInstalled = false;
    
    private Double existingPvPowerKwc;
    
    // Contraintes projet (Cas 2 - NEW)
    private Double projectBudgetDh;
    
    private Double totalAvailableSurfaceM2;
    
    private Integer populationServed;
    
    private Establishment.ProjectPriority projectPriority;
}


