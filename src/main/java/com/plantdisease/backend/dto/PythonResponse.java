package com.plantdisease.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class PythonResponse {
    @JsonProperty("class_name")
    private String className;

    @JsonProperty("class_id")
    private int classId;

    @JsonProperty("confidence")
    private double confidence;
}