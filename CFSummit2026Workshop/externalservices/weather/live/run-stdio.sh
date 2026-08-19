#!/bin/bash
# Weather MCP Server — LIVE (calls https://api.weather.gov)
# Tools: getWeatherForecastByLocation(latitude, longitude), getAlerts(state)
JAR_DIR="$(cd "$(dirname "$0")" && pwd)/target"
java -jar "$JAR_DIR/mcp-weather-stdio-server.jar" --spring.profiles.active=stdio
