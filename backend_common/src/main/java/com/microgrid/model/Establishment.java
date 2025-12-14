package com.microgrid.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "establishments")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Establishment {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(nullable = false, length = 200)
    private String name;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EstablishmentType type;
    
    @Column(nullable = false)
    private Integer numberOfBeds;
    
    @Column(length = 500)
    private String address;
    
    @Column(precision = 10)
    private Double latitude;
    
    @Column(precision = 11)
    private Double longitude;
    
    @Enumerated(EnumType.STRING)
    private IrradiationClass irradiationClass;
    
    // Surface et énergie
    @Column(name = "installable_surface_m2")
    private Double installableSurfaceM2;
    
    @Column(name = "non_critical_surface_m2")
    private Double nonCriticalSurfaceM2;
    
    @Column(name = "monthly_consumption_kwh")
    private Double monthlyConsumptionKwh;
    
    @Column(name = "existing_pv_installed")
    private Boolean existingPvInstalled = false;
    
    @Column(name = "existing_pv_power_kwc")
    private Double existingPvPowerKwc;
    
    // Contraintes projet (pour nouveau établissement)
    @Column(name = "project_budget_dh")
    private Double projectBudgetDh;
    
    @Column(name = "total_available_surface_m2")
    private Double totalAvailableSurfaceM2;
    
    @Column(name = "population_served")
    private Integer populationServed;
    
    // Objectifs
    @Enumerated(EnumType.STRING)
    private ProjectPriority projectPriority;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EstablishmentStatus status = EstablishmentStatus.ACTIVE;
    
    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;
    
    public enum EstablishmentType {
        // Selon Loi n° 70-13 et Décret n° 2-17-589
        CHU, // Centre Hospitalo-Universitaire
        
        // Selon Décret n° 2-14-562 - Réseau hospitalier
        HOPITAL_REGIONAL,
        HOPITAL_PREFECTORAL,
        HOPITAL_PROVINCIAL,
        CENTRE_REGIONAL_ONCOLOGIE,
        CENTRE_HEMODIALYSE,
        
        // Établissements médico-sociaux (Décret n° 2-14-562)
        CENTRE_REEDUCATION,
        CENTRE_ADDICTOLOGIE,
        CENTRE_SOINS_PALLIATIFS,
        
        // Dispositifs d'urgences (Décret n° 2-14-562)
        UMH, // Urgences médico-hospitalières
        UMP, // Urgences médicales de proximité
        UPH, // Urgences pré-hospitalières
        
        // Soins primaires (Décret n° 2-14-562)
        CENTRE_SANTE_PRIMAIRE,
        
        // Secteur privé
        CLINIQUE_PRIVEE
    }
    
    public enum IrradiationClass {
        A,  // Très élevée
        B,  // Élevée
        C,  // Moyenne (Casablanca)
        D   // Faible
    }
    
    public enum ProjectPriority {
        MINIMIZE_COST,
        MAXIMIZE_AUTONOMY,
        OPTIMIZE_ROI,
        BUILD_LARGEST
    }
    
    public enum EstablishmentStatus {
        ACTIVE,
        INACTIVE,
        PENDING
    }
}

