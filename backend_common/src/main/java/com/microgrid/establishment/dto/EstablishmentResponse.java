package com.microgrid.establishment.dto;

import com.microgrid.model.Establishment;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EstablishmentResponse {
    
    private Long id;
    private String name;
    private String type;
    private Integer numberOfBeds;
    private String address;
    private Double latitude;
    private Double longitude;
    private String irradiationClass;
    private Double installableSurfaceM2;
    private Double nonCriticalSurfaceM2;
    private Double monthlyConsumptionKwh;
    private Boolean existingPvInstalled;
    private Double existingPvPowerKwc;
    private Double projectBudgetDh;
    private Double totalAvailableSurfaceM2;
    private Integer populationServed;
    private String projectPriority;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    public static EstablishmentResponse fromEntity(Establishment establishment) {
        return new EstablishmentResponse(
            establishment.getId(),
            establishment.getName(),
            establishment.getType().name(),
            establishment.getNumberOfBeds(),
            establishment.getAddress(),
            establishment.getLatitude(),
            establishment.getLongitude(),
            establishment.getIrradiationClass() != null ? establishment.getIrradiationClass().name() : null,
            establishment.getInstallableSurfaceM2(),
            establishment.getNonCriticalSurfaceM2(),
            establishment.getMonthlyConsumptionKwh(),
            establishment.getExistingPvInstalled(),
            establishment.getExistingPvPowerKwc(),
            establishment.getProjectBudgetDh(),
            establishment.getTotalAvailableSurfaceM2(),
            establishment.getPopulationServed(),
            establishment.getProjectPriority() != null ? establishment.getProjectPriority().name() : null,
            establishment.getStatus().name(),
            establishment.getCreatedAt(),
            establishment.getUpdatedAt()
        );
    }
}


