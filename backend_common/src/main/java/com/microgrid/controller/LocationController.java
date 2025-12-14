package com.microgrid.controller;

import com.microgrid.model.Establishment.IrradiationClass;
import com.microgrid.model.MoroccanCity;
import com.microgrid.service.LocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/location")
@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:3000"})
public class LocationController {
    
    @Autowired
    private LocationService locationService;
    
    /**
     * Détermine la classe d'irradiation solaire selon les coordonnées GPS
     * GET /api/location/irradiation?latitude=33.5731&longitude=-7.5898
     */
    @GetMapping("/irradiation")
    public ResponseEntity<Map<String, Object>> getIrradiationClass(
            @RequestParam Double latitude,
            @RequestParam Double longitude) {
        
        IrradiationClass irradiationClass = locationService.determineIrradiationClass(latitude, longitude);
        Optional<MoroccanCity> nearestCity = locationService.getNearestCity(latitude, longitude);
        
        Map<String, Object> response = new HashMap<>();
        response.put("irradiationClass", irradiationClass.name());
        response.put("latitude", latitude);
        response.put("longitude", longitude);
        
        if (nearestCity.isPresent()) {
            Map<String, Object> cityInfo = new HashMap<>();
            cityInfo.put("name", nearestCity.get().getName());
            cityInfo.put("region", nearestCity.get().getRegion());
            response.put("nearestCity", cityInfo);
        }
        
        return ResponseEntity.ok(response);
    }
}


