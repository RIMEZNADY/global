package com.microgrid.establishment.service;

import com.microgrid.establishment.dto.EstablishmentRequest;
import com.microgrid.establishment.dto.EstablishmentResponse;
import com.microgrid.model.Establishment;
import com.microgrid.model.User;
import com.microgrid.repository.EstablishmentRepository;
import com.microgrid.repository.UserRepository;
import com.microgrid.service.LocationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class EstablishmentService {
    
    @Autowired
    private EstablishmentRepository establishmentRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private LocationService locationService;
    
    @Transactional
    public EstablishmentResponse createEstablishment(String userEmail, EstablishmentRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userEmail));
        
        Establishment establishment = new Establishment();
        establishment.setUser(user);
        establishment.setName(request.getName());
        establishment.setType(request.getType());
        establishment.setNumberOfBeds(request.getNumberOfBeds());
        establishment.setAddress(request.getAddress());
        establishment.setLatitude(request.getLatitude());
        establishment.setLongitude(request.getLongitude());
        
        // Déterminer automatiquement la classe d'irradiation si non fournie
        if (request.getIrradiationClass() == null && request.getLatitude() != null && request.getLongitude() != null) {
            establishment.setIrradiationClass(locationService.determineIrradiationClass(
                request.getLatitude(), 
                request.getLongitude()
            ));
        } else {
            establishment.setIrradiationClass(request.getIrradiationClass());
        }
        
        establishment.setInstallableSurfaceM2(request.getInstallableSurfaceM2());
        establishment.setNonCriticalSurfaceM2(request.getNonCriticalSurfaceM2());
        establishment.setMonthlyConsumptionKwh(request.getMonthlyConsumptionKwh());
        establishment.setExistingPvInstalled(request.getExistingPvInstalled());
        establishment.setExistingPvPowerKwc(request.getExistingPvPowerKwc());
        establishment.setProjectBudgetDh(request.getProjectBudgetDh());
        establishment.setTotalAvailableSurfaceM2(request.getTotalAvailableSurfaceM2());
        establishment.setPopulationServed(request.getPopulationServed());
        establishment.setProjectPriority(request.getProjectPriority());
        establishment.setStatus(Establishment.EstablishmentStatus.ACTIVE);
        
        establishment = establishmentRepository.save(establishment);
        
        return EstablishmentResponse.fromEntity(establishment);
    }
    
    @Transactional(readOnly = true)
    public List<EstablishmentResponse> getUserEstablishments(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userEmail));
        
        List<Establishment> establishments = establishmentRepository.findByUserId(user.getId());
        
        return establishments.stream()
                .map(EstablishmentResponse::fromEntity)
                .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public EstablishmentResponse getEstablishment(Long id, String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userEmail));
        
        Establishment establishment = establishmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Establishment not found"));
        
        // Vérifier que l'établissement appartient à l'utilisateur
        if (!establishment.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Unauthorized access to establishment");
        }
        
        return EstablishmentResponse.fromEntity(establishment);
    }
    
    @Transactional
    public EstablishmentResponse updateEstablishment(Long id, String userEmail, EstablishmentRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userEmail));
        
        Establishment establishment = establishmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Establishment not found"));
        
        // Vérifier que l'établissement appartient à l'utilisateur
        if (!establishment.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Unauthorized access to establishment");
        }
        
        // Mettre à jour les champs
        establishment.setName(request.getName());
        establishment.setType(request.getType());
        establishment.setNumberOfBeds(request.getNumberOfBeds());
        establishment.setAddress(request.getAddress());
        establishment.setLatitude(request.getLatitude());
        establishment.setLongitude(request.getLongitude());
        
        // Mettre à jour la classe d'irradiation si les coordonnées ont changé
        if (request.getLatitude() != null && request.getLongitude() != null) {
            if (establishment.getLatitude() == null || establishment.getLongitude() == null ||
                !request.getLatitude().equals(establishment.getLatitude()) || 
                !request.getLongitude().equals(establishment.getLongitude())) {
                // Coordonnées changées, recalculer la classe d'irradiation
                establishment.setIrradiationClass(locationService.determineIrradiationClass(
                    request.getLatitude(), 
                    request.getLongitude()
                ));
            } else if (request.getIrradiationClass() != null) {
                establishment.setIrradiationClass(request.getIrradiationClass());
            }
        } else if (request.getIrradiationClass() != null) {
            establishment.setIrradiationClass(request.getIrradiationClass());
        }
        
        establishment.setInstallableSurfaceM2(request.getInstallableSurfaceM2());
        establishment.setNonCriticalSurfaceM2(request.getNonCriticalSurfaceM2());
        establishment.setMonthlyConsumptionKwh(request.getMonthlyConsumptionKwh());
        establishment.setExistingPvInstalled(request.getExistingPvInstalled());
        establishment.setExistingPvPowerKwc(request.getExistingPvPowerKwc());
        establishment.setProjectBudgetDh(request.getProjectBudgetDh());
        establishment.setTotalAvailableSurfaceM2(request.getTotalAvailableSurfaceM2());
        establishment.setPopulationServed(request.getPopulationServed());
        establishment.setProjectPriority(request.getProjectPriority());
        
        establishment = establishmentRepository.save(establishment);
        
        return EstablishmentResponse.fromEntity(establishment);
    }
    
    @Transactional
    public void deleteEstablishment(Long id, String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userEmail));
        
        Establishment establishment = establishmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Establishment not found"));
        
        // Vérifier que l'établissement appartient à l'utilisateur
        if (!establishment.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Unauthorized access to establishment");
        }
        
        establishmentRepository.delete(establishment);
    }
    
    /**
     * Récupère l'entité Establishment (pour usage interne dans les services)
     */
    @Transactional(readOnly = true)
    public Establishment getEstablishmentEntity(Long id, String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userEmail));
        
        Establishment establishment = establishmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Establishment not found"));
        
        // Vérifier que l'établissement appartient à l'utilisateur
        if (!establishment.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Unauthorized access to establishment");
        }
        
        return establishment;
    }
    
    /**
     * Récupère l'entité Establishment par ID sans vérification d'email (pour usage interne)
     */
    @Transactional(readOnly = true)
    public Establishment getEstablishmentEntityById(Long id) {
        return establishmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Establishment not found"));
    }
}

