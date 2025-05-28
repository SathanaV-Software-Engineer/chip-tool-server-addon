#!/bin/bash

# Debug script to identify the chip-tool error source
echo "🔍 Debugging chip-tool error..."
echo "================================"

# Check if chip-tool server is running
echo "1. Checking chip-tool server status..."
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Chip-tool server is running on port 5000"
    curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health
else
    echo "❌ Chip-tool server is NOT running on port 5000"
    echo "   Please start the chip-tool server addon first:"
    echo "   cd chip-tool-server-addon && npm start"
fi

echo ""

# Check matter-controller status
echo "2. Checking matter-controller status..."
if curl -s http://localhost:8099/ > /dev/null 2>&1; then
    echo "✅ Matter-controller is running on port 8099"
else
    echo "❌ Matter-controller is NOT running on port 8099"
    echo "   Please start the matter-controller first"
fi

echo ""

# Test the pair endpoint with detailed error reporting
echo "3. Testing /pair endpoint with detailed error reporting..."

# Test with curl and capture full response
echo "Making request to http://localhost:8099/pair..."
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" \
  -X POST http://localhost:8099/pair \
  -H "Content-Type: application/json" \
  -d '{"node_id": 1, "code": "MT:Y.K90SO527JA0648G00"}' 2>&1)

echo "Full response:"
echo "$response"

echo ""

# Check environment variables in the container
echo "4. Checking environment variables..."
if command -v docker >/dev/null 2>&1; then
    container_id=$(docker ps --filter "publish=8099" --format "{{.ID}}" | head -1)
    if [ -n "$container_id" ]; then
        echo "Found container: $container_id"
        echo "Environment variables:"
        docker exec "$container_id" env | grep -E "(CHIP_TOOL|LOG_LEVEL)" || echo "No relevant env vars found"
        
        echo ""
        echo "Checking if chip-tool binary exists in container:"
        docker exec "$container_id" which chip-tool 2>/dev/null || echo "chip-tool not found in PATH"
        docker exec "$container_id" ls -la /usr/local/bin/chip-tool 2>/dev/null || echo "chip-tool not found in /usr/local/bin/"
        
        echo ""
        echo "Container logs (last 20 lines):"
        docker logs --tail 20 "$container_id"
    else
        echo "No container found running on port 8099"
    fi
else
    echo "Docker not available for container inspection"
fi

echo ""

# Test chip-tool server endpoints directly
echo "5. Testing chip-tool server endpoints..."
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "Testing /health endpoint:"
    curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health
    
    echo ""
    echo "Testing /config endpoint:"
    curl -s http://localhost:5000/config | jq . 2>/dev/null || curl -s http://localhost:5000/config
    
    echo ""
    echo "Testing /commission endpoint (this should fail with proper error):"
    curl -s -w "\nHTTP_STATUS:%{http_code}\n" \
      -X POST http://localhost:5000/commission \
      -H "Content-Type: application/json" \
      -d '{"nodeId": 1, "setupPayload": "MT:Y.K90SO527JA0648G00"}'
else
    echo "❌ Cannot test chip-tool server - not running"
fi

echo ""

# Check for any subprocess calls in the code
echo "6. Checking for subprocess calls in matter-controller code..."
if [ -d "matter-controller" ]; then
    echo "Searching for subprocess calls:"
    grep -r "subprocess\|shell=True\|chip-tool" matter-controller/rootfs/ 2>/dev/null || echo "No subprocess calls found"
    
    echo ""
    echo "Searching for any remaining direct chip-tool calls:"
    grep -r "chip-tool" matter-controller/rootfs/ 2>/dev/null | grep -v "CHIP_TOOL_SERVER_URL" || echo "No direct chip-tool calls found"
else
    echo "matter-controller directory not found"
fi

echo ""

# Provide recommendations
echo "7. Recommendations:"
echo "==================="

if ! curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "🔧 Start the chip-tool server first:"
    echo "   cd chip-tool-server-addon"
    echo "   npm install"
    echo "   npm start"
    echo ""
fi

if ! curl -s http://localhost:8099/ > /dev/null 2>&1; then
    echo "🔧 Start the matter-controller:"
    echo "   cd matter-controller"
    echo "   ./run_local_test.sh"
    echo ""
fi

echo "🔧 If both are running but still getting errors:"
echo "   1. Check the matter-controller logs for detailed error messages"
echo "   2. Verify the CHIP_TOOL_SERVER_URL environment variable is set correctly"
echo "   3. Ensure both services can communicate (no firewall blocking)"
echo "   4. Try restarting both services"

echo ""
echo "🎯 Quick test command:"
echo "   curl -X POST http://localhost:8099/pair -H 'Content-Type: application/json' -d '{\"node_id\": 1, \"code\": \"MT:TEST\"}'"
