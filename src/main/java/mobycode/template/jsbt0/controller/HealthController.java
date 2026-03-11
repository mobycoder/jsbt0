package mobycode.template.jsbt0.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Custom REST health endpoint.
 *
 * GET /health → {"status":"UP"}
 *
 * Spring Boot Actuator also exposes a richer health endpoint at:
 *   GET /actuator/health
 * (configured in application.yml)
 */
@RestController
public class HealthController {

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "UP"));
    }
}
