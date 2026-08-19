#!/bin/bash
# Weather MCP Server — LIVE HTTP mode (port 8085)
JAR_DIR="$(cd "$(dirname "$0")" && pwd)/target"
java -jar "$JAR_DIR/mcp-weather-stdio-server.jar" --server.port=8085
