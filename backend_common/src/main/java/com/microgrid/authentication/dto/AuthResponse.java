package com.microgrid.authentication.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    
    private String token;
    private String type = "Bearer";
    private Long userId;
    private String email;
    private String firstName;
    private String lastName;
    private List<EstablishmentSummary> establishments;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EstablishmentSummary {
        private Long id;
        private String name;
        private String type;
        private String status;
    }
}


