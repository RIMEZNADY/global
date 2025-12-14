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
    
    // Équipements sélectionnés
    private String selectedPanelId;
    private Double selectedPanelPrice;
    private String selectedBatteryId;
    private Double selectedBatteryPrice;
    private String selectedInverterId;
    private Double selectedInverterPrice;
    private String selectedControllerId;
    private Double selectedControllerPrice;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    public static EstablishmentResponse fromEntity(Establishment establishment) {
        EstablishmentResponse response = new EstablishmentResponse();
        response.setId(establishment.getId());
        response.setName(establishment.getName());
        response.setType(establishment.getType().name());
        response.setNumberOfBeds(establishment.getNumberOfBeds());
        response.setAddress(establishment.getAddress());
        response.setLatitude(establishment.getLatitude());
        response.setLongitude(establishment.getLongitude());
        response.setIrradiationClass(establishment.getIrradiationClass() != null ? establishment.getIrradiationClass().name() : null);
        response.setInstallableSurfaceM2(establishment.getInstallableSurfaceM2());
        response.setNonCriticalSurfaceM2(establishment.getNonCriticalSurfaceM2());
        response.setMonthlyConsumptionKwh(establishment.getMonthlyConsumptionKwh());
        response.setExistingPvInstalled(establishment.getExistingPvInstalled());
        response.setExistingPvPowerKwc(establishment.getExistingPvPowerKwc());
        response.setProjectBudgetDh(establishment.getProjectBudgetDh());
        response.setTotalAvailableSurfaceM2(establishment.getTotalAvailableSurfaceM2());
        response.setPopulationServed(establishment.getPopulationServed());
        response.setProjectPriority(establishment.getProjectPriority() != null ? establishment.getProjectPriority().name() : null);
        response.setStatus(establishment.getStatus().name());
        
        // Équipements sélectionnés
        response.setSelectedPanelId(establishment.getSelectedPanelId());
        response.setSelectedPanelPrice(establishment.getSelectedPanelPrice());
        response.setSelectedBatteryId(establishment.getSelectedBatteryId());
        response.setSelectedBatteryPrice(establishment.getSelectedBatteryPrice());
        response.setSelectedInverterId(establishment.getSelectedInverterId());
        response.setSelectedInverterPrice(establishment.getSelectedInverterPrice());
        response.setSelectedControllerId(establishment.getSelectedControllerId());
        response.setSelectedControllerPrice(establishment.getSelectedControllerPrice());
        
        response.setCreatedAt(establishment.getCreatedAt());
        response.setUpdatedAt(establishment.getUpdatedAt());
        
        return response;
    }
}


