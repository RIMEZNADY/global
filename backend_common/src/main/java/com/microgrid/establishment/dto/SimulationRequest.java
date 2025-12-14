package com.microgrid.establishment.dto;

import lombok.Data;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

@Data
public class SimulationRequest {
    
    @NotNull(message = "La date de début est requise")
    private LocalDateTime startDate;
    
    @Min(value = 1, message = "Le nombre de jours doit être au moins 1")
    private int days = 7; // Par défaut 7 jours
    
    @Min(value = 0, message = "La capacité batterie doit être positive")
    private Double batteryCapacityKwh = 500.0; // Par défaut 500 kWh
    
    @Min(value = 0, message = "Le SOC initial doit être positif")
    private Double initialSocKwh = 250.0; // Par défaut 50% de 500 kWh
}


