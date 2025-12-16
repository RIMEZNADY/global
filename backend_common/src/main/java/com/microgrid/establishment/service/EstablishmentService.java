package com.microgrid.establishment.service;

import com.microgrid.establishment.dto.EstablishmentRequest;
import com.microgrid.establishment.dto.EstablishmentResponse;
import com.microgrid.exception.ValidationException;
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
        // Validations métier
        validateEstablishmentRequest(request);
        
        // Créer ou récupérer l'utilisateur (guest par défaut si pas d'authentification)
        User user = userRepository.findByEmail(userEmail).orElseGet(() -> {
            // Créer un utilisateur guest si il n'existe pas
            User guestUser = new User();
            guestUser.setEmail(userEmail);
            guestUser.setFirstName("Guest");
            guestUser.setLastName("User");
            guestUser.setRole(User.Role.USER);
            guestUser.setActive(true);
            // Pas de mot de passe pour les utilisateurs guest
            guestUser.setPassword("$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"); // Mot de passe hashé par défaut
            return userRepository.save(guestUser);
        });
        
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
        
        // Équipements sélectionnés
        establishment.setSelectedPanelId(request.getSelectedPanelId());
        establishment.setSelectedPanelPrice(request.getSelectedPanelPrice());
        establishment.setSelectedBatteryId(request.getSelectedBatteryId());
        establishment.setSelectedBatteryPrice(request.getSelectedBatteryPrice());
        establishment.setSelectedInverterId(request.getSelectedInverterId());
        establishment.setSelectedInverterPrice(request.getSelectedInverterPrice());
        establishment.setSelectedControllerId(request.getSelectedControllerId());
        establishment.setSelectedControllerPrice(request.getSelectedControllerPrice());
        
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
        // Validations métier
        validateEstablishmentRequest(request);
        
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
        
        // Équipements sélectionnés
        establishment.setSelectedPanelId(request.getSelectedPanelId());
        establishment.setSelectedPanelPrice(request.getSelectedPanelPrice());
        establishment.setSelectedBatteryId(request.getSelectedBatteryId());
        establishment.setSelectedBatteryPrice(request.getSelectedBatteryPrice());
        establishment.setSelectedInverterId(request.getSelectedInverterId());
        establishment.setSelectedInverterPrice(request.getSelectedInverterPrice());
        establishment.setSelectedControllerId(request.getSelectedControllerId());
        establishment.setSelectedControllerPrice(request.getSelectedControllerPrice());
        
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
    
    /**
     * Valide les données de la requête selon les règles métier
     */
    private void validateEstablishmentRequest(EstablishmentRequest request) {
        // A. Validation cohérence des surfaces
        if (request.getInstallableSurfaceM2() != null && request.getTotalAvailableSurfaceM2() != null) {
            if (request.getInstallableSurfaceM2() > request.getTotalAvailableSurfaceM2()) {
                throw new ValidationException(
                    "La surface installable (" + request.getInstallableSurfaceM2() + " m²) " +
                    "ne peut pas dépasser la surface totale disponible (" + request.getTotalAvailableSurfaceM2() + " m²)"
                );
            }
        }
        
        // B. Validation cohérence PV existant
        if (request.getExistingPvInstalled() != null && request.getExistingPvInstalled()) {
            if (request.getExistingPvPowerKwc() == null || request.getExistingPvPowerKwc() <= 0) {
                throw new ValidationException(
                    "Si un système PV existant est installé, la puissance PV existante (existingPvPowerKwc) doit être renseignée et positive"
                );
            }
        }
        
        // C. Validation workflow EXISTANT vs NEW
        boolean isExisting = request.getMonthlyConsumptionKwh() != null;
        boolean isNew = request.getProjectBudgetDh() != null;
        
        if (isExisting) {
            // Workflow EXISTANT : consommation mensuelle requise
            if (request.getMonthlyConsumptionKwh() == null || request.getMonthlyConsumptionKwh() <= 0) {
                throw new ValidationException(
                    "Workflow EXISTANT : la consommation mensuelle (monthlyConsumptionKwh) est requise et doit être positive"
                );
            }
            if (request.getInstallableSurfaceM2() == null || request.getInstallableSurfaceM2() <= 0) {
                throw new ValidationException(
                    "Workflow EXISTANT : la surface installable (installableSurfaceM2) est requise et doit être positive"
                );
            }
        }
        
        if (isNew) {
            // Workflow NEW : budget projet requis
            if (request.getProjectBudgetDh() == null || request.getProjectBudgetDh() <= 0) {
                throw new ValidationException(
                    "Workflow NEW : le budget projet (projectBudgetDh) est requis et doit être positif"
                );
            }
            if (request.getTotalAvailableSurfaceM2() == null || request.getTotalAvailableSurfaceM2() <= 0) {
                throw new ValidationException(
                    "Workflow NEW : la surface totale disponible (totalAvailableSurfaceM2) est requise et doit être positive"
                );
            }
        }
        
        // D. Validation valeurs positives
        if (request.getInstallableSurfaceM2() != null && request.getInstallableSurfaceM2() < 0) {
            throw new ValidationException("La surface installable ne peut pas être négative");
        }
        if (request.getMonthlyConsumptionKwh() != null && request.getMonthlyConsumptionKwh() < 0) {
            throw new ValidationException("La consommation mensuelle ne peut pas être négative");
        }
        if (request.getExistingPvPowerKwc() != null && request.getExistingPvPowerKwc() < 0) {
            throw new ValidationException("La puissance PV existante ne peut pas être négative");
        }
    }
}

