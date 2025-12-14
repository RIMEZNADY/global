package com.microgrid.repository;

import com.microgrid.model.MoroccanCity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MoroccanCityRepository extends JpaRepository<MoroccanCity, Long> {
    
    Optional<MoroccanCity> findByNameIgnoreCase(String name);
    
    List<MoroccanCity> findByIrradiationClass(MoroccanCity.IrradiationClass irradiationClass);
    
    // Trouve la ville la plus proche d'un point GPS
    @Query(value = """
        SELECT * FROM moroccan_cities
        ORDER BY (
            6371 * acos(
                cos(radians(:lat)) * cos(radians(latitude)) *
                cos(radians(longitude) - radians(:lon)) +
                sin(radians(:lat)) * sin(radians(latitude))
            )
        ) ASC
        LIMIT 1
        """, nativeQuery = true)
    Optional<MoroccanCity> findNearestCity(@Param("lat") Double latitude, @Param("lon") Double longitude);
}


