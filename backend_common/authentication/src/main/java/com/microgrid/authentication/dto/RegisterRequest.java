package com.microgrid.authentication.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    
    @NotBlank(message = "L'email est requis")
    @Email(message = "L'email doit être valide")
    @Size(max = 100, message = "L'email ne peut pas dépasser 100 caractères")
    private String email;
    
    @NotBlank(message = "Le mot de passe est requis")
    @Size(min = 6, message = "Le mot de passe doit contenir au moins 6 caractères")
    private String password;
    
    @NotBlank(message = "Le prénom est requis")
    @Size(max = 100, message = "Le prénom ne peut pas dépasser 100 caractères")
    private String firstName;
    
    @NotBlank(message = "Le nom est requis")
    @Size(max = 100, message = "Le nom ne peut pas dépasser 100 caractères")
    private String lastName;
    
    @Size(max = 20, message = "Le téléphone ne peut pas dépasser 20 caractères")
    private String phone;
}


