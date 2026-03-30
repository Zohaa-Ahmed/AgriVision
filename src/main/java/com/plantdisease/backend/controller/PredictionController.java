package com.plantdisease.backend.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import com.plantdisease.backend.dto.PythonResponse;
import com.plantdisease.backend.model.Disease;
import com.plantdisease.backend.repository.DiseaseRepository;

@RestController
@RequestMapping("/api")
public class PredictionController {

    private final DiseaseRepository diseaseRepository;
    private final RestTemplate restTemplate;

    // URL of your Python Service
    private final String PYTHON_API_URL = "https://agrivision-ai-service.onrender.com/predict";

    public PredictionController(DiseaseRepository diseaseRepository) {
        this.diseaseRepository = diseaseRepository;
        this.restTemplate = new RestTemplate();
    }

    @PostMapping("/detect")
    public ResponseEntity<?> detectDisease(@RequestParam("image") MultipartFile file) {
        try {
            // 1. Validate file
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("Please upload an image");
            }

            // 2. Prepare request for Python API
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", file.getResource());

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // 3. Call Python API
            ResponseEntity<PythonResponse> pythonResponse = restTemplate.postForEntity(
                    PYTHON_API_URL,
                    requestEntity,
                    PythonResponse.class
            );

            PythonResponse result = pythonResponse.getBody();

            if (result == null) {
                return ResponseEntity.status(500).body("AI Service returned no data");
            }

            
            double confidenceThreshold = 0.70;
            Map<String, Object> finalResponse = new HashMap<>(); // Initialized ONCE here
            finalResponse.put("confidence", result.getConfidence());

            if (result.getConfidence() < confidenceThreshold) {
                finalResponse.put("disease_name", "Low Confidence / Unknown");
                finalResponse.put("description", "The AI is not sure what this is. It might be blurry or not a plant leaf.");
                finalResponse.put("treatment", "Please take a clearer photo in better lighting, focusing on the leaf.");
                return ResponseEntity.ok(finalResponse);
            }

            // 4. Fetch Treatment (Only if confidence is high)
            Disease diseaseInfo = diseaseRepository.findByName(result.getClassName());

            // 5. Construct Final Response (Reuse the finalResponse map)
            finalResponse.put("disease_name", result.getClassName());

            if (diseaseInfo != null) {
                finalResponse.put("description", diseaseInfo.getDescription());
                finalResponse.put("treatment", diseaseInfo.getTreatment());
            } else {
                finalResponse.put("description", "No information available for this disease.");
                finalResponse.put("treatment", "Consult an expert.");
            }

            return ResponseEntity.ok(finalResponse);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("Error processing request: " + e.getMessage());
        }
    }
}