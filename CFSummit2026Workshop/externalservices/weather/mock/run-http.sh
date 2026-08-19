#!/bin/bash
# Weather MCP Server — MOCK HTTP mode (port 8086)
JAR_DIR="$(cd "$(dirname "$0")" && pwd)/target"
java -jar "$JAR_DIR/mcp-weather-mock-server.jar" --server.port=8086
