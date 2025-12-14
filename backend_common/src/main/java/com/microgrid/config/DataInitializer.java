package com.microgrid.config;

import com.microgrid.model.MoroccanCity;
import com.microgrid.repository.MoroccanCityRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DataInitializer {
    
    @Autowired
    private MoroccanCityRepository cityRepository;
    
    @PostConstruct
    public void initCities() {
        if (cityRepository.count() > 0) {
            return; // Les données sont déjà chargées
        }
        
        List<MoroccanCity> cities = List.of(
            // Classe A: Très élevée (Sud-Est, Sahara)
            new MoroccanCity(null, "Ouarzazate", "Drâa-Tafilalet", 30.9333, -6.9167, MoroccanCity.IrradiationClass.A),
            new MoroccanCity(null, "Errachidia", "Drâa-Tafilalet", 31.9333, -4.4167, MoroccanCity.IrradiationClass.A),
            new MoroccanCity(null, "Zagora", "Drâa-Tafilalet", 30.3333, -5.8333, MoroccanCity.IrradiationClass.A),
            new MoroccanCity(null, "Tata", "Guelmim-Oued Noun", 29.7500, -7.9667, MoroccanCity.IrradiationClass.A),
            new MoroccanCity(null, "Tan-Tan", "Guelmim-Oued Noun", 28.4333, -11.1000, MoroccanCity.IrradiationClass.A),
            new MoroccanCity(null, "Laâyoune", "Laâyoune-Sakia El Hamra", 27.1500, -13.2000, MoroccanCity.IrradiationClass.A),
            new MoroccanCity(null, "Dakhla", "Dakhla-Oued Ed-Dahab", 23.7167, -15.9500, MoroccanCity.IrradiationClass.A),
            
            // Classe B: Élevée (Centre, Sud)
            new MoroccanCity(null, "Marrakech", "Marrakech-Safi", 31.6295, -7.9811, MoroccanCity.IrradiationClass.B),
            new MoroccanCity(null, "Agadir", "Souss-Massa", 30.4278, -9.5981, MoroccanCity.IrradiationClass.B),
            new MoroccanCity(null, "Safi", "Marrakech-Safi", 32.2833, -9.2333, MoroccanCity.IrradiationClass.B),
            new MoroccanCity(null, "Essaouira", "Marrakech-Safi", 31.5131, -9.7697, MoroccanCity.IrradiationClass.B),
            new MoroccanCity(null, "El Jadida", "Casablanca-Settat", 33.2544, -8.5061, MoroccanCity.IrradiationClass.B),
            new MoroccanCity(null, "Beni Mellal", "Béni Mellal-Khénifra", 32.3394, -6.3608, MoroccanCity.IrradiationClass.B),
            new MoroccanCity(null, "Khouribga", "Béni Mellal-Khénifra", 32.8833, -6.9000, MoroccanCity.IrradiationClass.B),
            new MoroccanCity(null, "Settat", "Casablanca-Settat", 33.0000, -7.6167, MoroccanCity.IrradiationClass.B),
            new MoroccanCity(null, "Berrechid", "Casablanca-Settat", 33.2667, -7.5833, MoroccanCity.IrradiationClass.B),
            
            // Classe C: Moyenne (Nord, Côtes - incluant Casablanca)
            new MoroccanCity(null, "Casablanca", "Casablanca-Settat", 33.5731, -7.5898, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Rabat", "Rabat-Salé-Kénitra", 34.0209, -6.8416, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Salé", "Rabat-Salé-Kénitra", 34.0500, -6.8167, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Témara", "Rabat-Salé-Kénitra", 33.9167, -6.9167, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Mohammedia", "Casablanca-Settat", 33.6833, -7.3833, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Kénitra", "Rabat-Salé-Kénitra", 34.2500, -6.5833, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Meknès", "Fès-Meknès", 33.8950, -5.5547, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Fès", "Fès-Meknès", 34.0331, -5.0003, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Taza", "Fès-Meknès", 34.2167, -4.0167, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Oujda", "Oriental", 34.6867, -1.9114, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Nador", "Oriental", 35.1681, -2.9336, MoroccanCity.IrradiationClass.C),
            new MoroccanCity(null, "Al Hoceima", "Tanger-Tétouan-Al Hoceima", 35.2500, -3.9333, MoroccanCity.IrradiationClass.C),
            
            // Classe D: Faible (Rif, Hautes altitudes)
            new MoroccanCity(null, "Tanger", "Tanger-Tétouan-Al Hoceima", 35.7595, -5.8340, MoroccanCity.IrradiationClass.D),
            new MoroccanCity(null, "Tétouan", "Tanger-Tétouan-Al Hoceima", 35.5711, -5.3724, MoroccanCity.IrradiationClass.D),
            new MoroccanCity(null, "Chefchaouen", "Tanger-Tétouan-Al Hoceima", 35.1714, -5.2697, MoroccanCity.IrradiationClass.D),
            new MoroccanCity(null, "Larache", "Tanger-Tétouan-Al Hoceima", 35.1833, -6.1500, MoroccanCity.IrradiationClass.D),
            new MoroccanCity(null, "Ifrane", "Fès-Meknès", 33.5333, -5.1167, MoroccanCity.IrradiationClass.D),
            new MoroccanCity(null, "Azrou", "Fès-Meknès", 33.4333, -5.2167, MoroccanCity.IrradiationClass.D),
            new MoroccanCity(null, "Midelt", "Drâa-Tafilalet", 32.6833, -4.7333, MoroccanCity.IrradiationClass.D)
        );
        
        cityRepository.saveAll(cities);
    }
}


