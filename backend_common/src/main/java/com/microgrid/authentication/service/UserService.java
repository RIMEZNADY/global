package com.microgrid.authentication.service;

import com.microgrid.authentication.dto.UserResponse;
import com.microgrid.model.Establishment;
import com.microgrid.model.User;
import com.microgrid.repository.EstablishmentRepository;
import com.microgrid.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private EstablishmentRepository establishmentRepository;
    
    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
        
        List<Establishment> establishments = establishmentRepository.findByUserId(user.getId());
        
        List<UserResponse.EstablishmentSummary> establishmentSummaries = establishments.stream()
                .map(est -> new UserResponse.EstablishmentSummary(
                    est.getId(),
                    est.getName(),
                    est.getType().name(),
                    est.getStatus().name(),
                    est.getCreatedAt()
                ))
                .collect(Collectors.toList());
        
        return new UserResponse(
            user.getId(),
            user.getEmail(),
            user.getFirstName(),
            user.getLastName(),
            user.getPhone(),
            user.getRole().name(),
            user.getActive(),
            user.getCreatedAt(),
            establishmentSummaries
        );
    }
    
    @Transactional
    public UserResponse updateUser(String email, com.microgrid.authentication.dto.UpdateUserRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
        
        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName());
        }
        if (request.getPhone() != null) {
            user.setPhone(request.getPhone());
        }
        
        user = userRepository.save(user);
        
        List<Establishment> establishments = establishmentRepository.findByUserId(user.getId());
        List<UserResponse.EstablishmentSummary> establishmentSummaries = establishments.stream()
                .map(est -> new UserResponse.EstablishmentSummary(
                    est.getId(),
                    est.getName(),
                    est.getType().name(),
                    est.getStatus().name(),
                    est.getCreatedAt()
                ))
                .collect(Collectors.toList());
        
        return new UserResponse(
            user.getId(),
            user.getEmail(),
            user.getFirstName(),
            user.getLastName(),
            user.getPhone(),
            user.getRole().name(),
            user.getActive(),
            user.getCreatedAt(),
            establishmentSummaries
        );
    }
    
    @Transactional
    public void deleteUser(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
        
        // Delete all establishments first
        List<Establishment> establishments = establishmentRepository.findByUserId(user.getId());
        establishmentRepository.deleteAll(establishments);
        
        // Then delete the user
        userRepository.delete(user);
    }
}


