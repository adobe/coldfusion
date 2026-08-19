#!/bin/bash
# Weather MCP Server — MOCK (no external API calls, deterministic data)
# Tools: getMockWeatherForecast(lat, lon), getMockAlerts(state), getCurrentTemperature(city)
JAR_DIR="$(cd "$(dirname "$0")" && pwd)/target"
java -jar "$JAR_DIR/mcp-weather-mock-server.jar" --spring.profiles.active=stdio
