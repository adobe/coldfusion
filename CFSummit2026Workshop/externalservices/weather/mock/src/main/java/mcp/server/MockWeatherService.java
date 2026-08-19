package mcp.server;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * Mock Weather Service for MCP testing
 * Provides simple weather tools without external API calls
 */
@Service
public class MockWeatherService {

    private static final Logger logger = LogManager.getLogger(MockWeatherService.class);

    /**
     * Get mock forecast for a specific latitude/longitude
     * @param latitude Latitude
     * @param longitude Longitude
     * @return Mock forecast for the given location
     */
    @Tool(description = "Get mock weather forecast for a specific latitude/longitude")
    public String getMockWeatherForecast(
            @ToolParam(description = "Latitude coordinate") double latitude,
            @ToolParam(description = "Longitude coordinate") double longitude) {

        logger.info("getMockWeatherForecast called with latitude: {}, longitude: {}", latitude, longitude);

        // Return mock data
        return String.format("""
                Today:
                Temperature: 72 F
                Wind: 10 mph NW
                Forecast: Partly cloudy with a chance of sunshine

                Tonight:
                Temperature: 58 F
                Wind: 5 mph N
                Forecast: Clear skies

                Location: lat=%.4f, lon=%.4f
                """, latitude, longitude);
    }

    /**
     * Get mock alerts for a specific state
     * @param state Two-letter US state code (e.g. CA, NY)
     * @return Mock alert information
     */
    @Tool(description = "Get mock weather alerts for a US state. Input is Two-letter US state code (e.g. CA, NY)")
    public String getMockAlerts(@ToolParam(description = "Two-letter US state code (e.g. CA, NY)") String state) {
        logger.info("getMockAlerts called with state: {}", state);

        // Return mock alert data
        if (state.equalsIgnoreCase("CA") || state.equalsIgnoreCase("NY")) {
            return String.format("""
                    Event: High Wind Warning
                    Area: %s
                    Severity: Moderate
                    Description: Winds may gust up to 40 mph
                    Instructions: Secure loose outdoor objects

                    State: %s (MOCK DATA)
                    """, state.toUpperCase(), state.toUpperCase());
        } else {
            return String.format("No active alerts for state: %s (MOCK DATA)", state.toUpperCase());
        }
    }

    /**
     * Get current temperature for a city (mock)
     * @param city City name
     * @return Mock temperature information
     */
    @Tool(description = "Get current mock temperature for a city")
    public String getCurrentTemperature(@ToolParam(description = "City name") String city) {
        logger.info("getCurrentTemperature called with city: {}", city);

        // Generate a pseudo-random temperature based on city name length
        int baseTemp = 60 + (city.length() % 30);

        return String.format("""
                Current Temperature for %s:
                Temperature: %d°F
                Conditions: Partly Cloudy
                Humidity: 65%%

                (MOCK DATA)
                """, city, baseTemp);
    }

    /**
     * Read an environment variable from the JVM process environment.
     * Used by tests that inject env vars via MCPClient transport `env` config to
     * verify they are passed through to the spawned STDIO server process.
     *
     * @param envVarName Name of the environment variable to read
     * @return The variable's value, or a structured "not found" / "cannot be null or empty" message
     */
    @Tool(description = "Get the value of an environment variable in the MCP server JVM process")
    public String getEnvironmentVariable(
            @ToolParam(description = "Name of the environment variable to read") String envVarName) {
        if (envVarName == null || envVarName.isEmpty()) {
            return "Error: envVarName cannot be null or empty";
        }
        String value = System.getenv(envVarName);
        if (value == null) {
            return "Environment variable not found: " + envVarName;
        }
        return value;
    }
}
