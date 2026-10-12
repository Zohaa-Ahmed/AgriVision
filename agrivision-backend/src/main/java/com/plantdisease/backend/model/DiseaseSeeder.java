package com.plantdisease.backend.model;

import com.plantdisease.backend.repository.DiseaseRepository; // We will create this next
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;

@Component
public class DiseaseSeeder implements CommandLineRunner {

    private final DiseaseRepository diseaseRepository;

    public DiseaseSeeder(DiseaseRepository diseaseRepository) {
        this.diseaseRepository = diseaseRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        // Load labels.txt from src/main/resources
        ClassPathResource resource = new ClassPathResource("labels.txt");

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String diseaseName = line.strip();

                if (!diseaseName.isEmpty() && !diseaseRepository.existsByName(diseaseName)) {
                    Disease disease = new Disease();
                    disease.setName(diseaseName);
                    disease.setDescription("Auto-generated description for " + diseaseName);
                    disease.setTreatment("Standard treatment for " + diseaseName);

                    diseaseRepository.save(disease);
                    System.out.println("Seeded database with: " + diseaseName);
                }
            }
        } catch (Exception e) {
            System.out.println("Could not seed database (labels.txt might be missing): " + e.getMessage());
        }
    }
}