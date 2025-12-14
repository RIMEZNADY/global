package com.microgrid.authentication.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {
    
    private Long id;
    private String email;
    private String firstName;
    private String lastName;
    private String phone;
    private String role;
    private Boolean active;
    private LocalDateTime createdAt;
    private List<EstablishmentSummary> establishments;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EstablishmentSummary {
        private Long id;
        private String name;
        private String type;
        private String status;
        private LocalDateTime createdAt;
    }
}


