package com.microgrid.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/public")
@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:3000"})
public class HealthController {
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "service", "microgrid-backend",
            "timestamp", System.currentTimeMillis()
        ));
    }
}


