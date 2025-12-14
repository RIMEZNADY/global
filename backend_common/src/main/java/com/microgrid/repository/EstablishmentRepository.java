package com.microgrid.repository;

import com.microgrid.model.Establishment;
import com.microgrid.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EstablishmentRepository extends JpaRepository<Establishment, Long> {
    
    List<Establishment> findByUser(User user);
    
    List<Establishment> findByUserId(Long userId);
    
    List<Establishment> findByUserIdAndStatus(Long userId, Establishment.EstablishmentStatus status);
}


