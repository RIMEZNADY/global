package com.microgrid.authentication.service;

import com.microgrid.authentication.dto.AuthResponse;
import com.microgrid.authentication.dto.LoginRequest;
import com.microgrid.authentication.dto.RegisterRequest;
import com.microgrid.authentication.security.JwtTokenProvider;
import com.microgrid.model.Establishment;
import com.microgrid.model.User;
import com.microgrid.repository.EstablishmentRepository;
import com.microgrid.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AuthService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private EstablishmentRepository establishmentRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Autowired
    private AuthenticationManager authenticationManager;
    
    @Autowired
    private JwtTokenProvider tokenProvider;
    
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Un utilisateur avec cet email existe déjà");
        }
        
        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setPhone(request.getPhone());
        user.setRole(User.Role.USER);
        user.setActive(true);
        
        user = userRepository.save(user);
        
        String token = tokenProvider.generateTokenFromEmail(user.getEmail());
        
        return buildAuthResponse(user, token);
    }
    
    public AuthResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(
                request.getEmail(),
                request.getPassword()
            )
        );
        
        SecurityContextHolder.getContext().setAuthentication(authentication);
        
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
        
        String token = tokenProvider.generateToken(authentication);
        
        return buildAuthResponse(user, token);
    }
    
    private AuthResponse buildAuthResponse(User user, String token) {
        List<Establishment> establishments = establishmentRepository.findByUserId(user.getId());
        
        List<AuthResponse.EstablishmentSummary> establishmentSummaries = establishments.stream()
                .map(est -> new AuthResponse.EstablishmentSummary(
                    est.getId(),
                    est.getName(),
                    est.getType().name(),
                    est.getStatus().name()
                ))
                .collect(Collectors.toList());
        
        return new AuthResponse(
            token,
            "Bearer",
            user.getId(),
            user.getEmail(),
            user.getFirstName(),
            user.getLastName(),
            establishmentSummaries
        );
    }
}


