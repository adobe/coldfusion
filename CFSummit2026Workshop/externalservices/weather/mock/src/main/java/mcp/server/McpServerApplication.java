package mcp.server;

import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.ai.tool.method.MethodToolCallbackProvider;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/**
 * MCP Server Application with only Tools capability enabled
 *
 * This server demonstrates MCP capability configuration by:
 * - Enabling: tools capability
 * - Disabling: resources and prompts capabilities
 *
 * Configuration is set in application.properties
 */
@SpringBootApplication
public class McpServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(McpServerApplication.class, args);
    }

    /**
     * Register weather tools with the MCP server
     * Only tools capability is enabled in this server
     */
    @Bean
    public ToolCallbackProvider mockWeatherTools(MockWeatherService mockWeatherService) {
        return MethodToolCallbackProvider.builder()
                .toolObjects(mockWeatherService)
                .build();
    }
}
