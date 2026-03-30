package com.plantdisease.backend.repository;

import com.plantdisease.backend.model.Disease;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DiseaseRepository extends JpaRepository<Disease, Long> {
    // This helps us check if a disease already exists so we don't save duplicates
    boolean existsByName(String name);

    // We will need this later to find the cure by name
    Disease findByName(String name);
}