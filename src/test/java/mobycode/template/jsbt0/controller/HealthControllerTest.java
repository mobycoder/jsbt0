package mobycode.template.jsbt0.controller;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Plain unit test for HealthController — no Spring context required.
 * Spring Boot 4 removed @WebMvcTest; use @SpringBootTest(webEnvironment=RANDOM_PORT)
 * with TestRestTemplate if you need a full HTTP round-trip test.
 */
class HealthControllerTest {

    private final HealthController controller = new HealthController();

    @Test
    void healthEndpointReturnsOk() {
        ResponseEntity<Map<String, String>> response = controller.health();
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void healthEndpointBodyContainsStatusUp() {
        ResponseEntity<Map<String, String>> response = controller.health();
        assertThat(response.getBody()).containsEntry("status", "UP");
    }
}
