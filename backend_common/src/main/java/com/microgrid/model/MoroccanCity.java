package com.microgrid.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "moroccan_cities")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MoroccanCity {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 100)
    private String name;
    
    @Column(nullable = false, length = 100)
    private String region;
    
    @Column(nullable = false, precision = 10)
    private Double latitude;
    
    @Column(nullable = false, precision = 11)
    private Double longitude;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 1)
    private IrradiationClass irradiationClass;
    
    // Classe d'irradiation solaire
    public enum IrradiationClass {
        A,  // Très élevée (Sud-Est, Sahara)
        B,  // Élevée (Centre, Sud)
        C,  // Moyenne (Nord, Côtes - ex: Casablanca)
        D   // Faible (Rif, Hautes altitudes)
    }
}

