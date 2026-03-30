package com.plantdisease.backend.controller;

import com.plantdisease.backend.dto.PythonResponse;
import com.plantdisease.backend.model.Disease;
import com.plantdisease.backend.repository.DiseaseRepository;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

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

            // 4. Fetch Treatment from Database using the Name from Python
            Disease diseaseInfo = diseaseRepository.findByName(result.getClassName());

            // 5. Construct Final Response
            Map<String, Object> finalResponse = new HashMap<>();
            finalResponse.put("disease_name", result.getClassName());
            finalResponse.put("confidence", result.getConfidence());

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