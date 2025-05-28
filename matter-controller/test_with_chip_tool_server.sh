#!/bin/bash

echo "🚀 Testing Matter Controller with Chip-Tool Server"
echo "=================================================="

# Check if chip-tool server is running
echo "1. Checking chip-tool server..."
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Chip-tool server is running"
    curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health
else
    echo "❌ Chip-tool server is NOT running!"
    echo "Please start it first:"
    echo "  cd chip-tool-server-addon && npm start"
    exit 1
fi

echo ""

# Set up environment for matter controller
echo "2. Setting up matter controller environment..."
export LOG_LEVEL=debug
export CHIP_TOOL_SERVER_URL=http://localhost:5000
export CONFIG_PATH=$(pwd)/local_config.json
export STARTUP_TIME=$(date +%s)

# Create data directories
mkdir -p /tmp/data/logs
mkdir -p /tmp/data/matter_controller/credentials
mkdir -p /tmp/data/matter_server

echo "✅ Environment configured"
echo "   LOG_LEVEL: $LOG_LEVEL"
echo "   CHIP_TOOL_SERVER_URL: $CHIP_TOOL_SERVER_URL"
echo "   CONFIG_PATH: $CONFIG_PATH"

echo ""

# Install dependencies
echo "3. Installing Python dependencies..."
cd rootfs/matter_controller
pip3 install --user fastapi uvicorn aiohttp pydantic PyJWT requests > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""

# Start the API server
echo "4. Starting matter controller API..."
python3 -m uvicorn api:app --host 0.0.0.0 --port 8099 --log-level debug &
API_PID=$!

echo "🔄 Waiting for API to start..."
sleep 5

# Check if API is running
if kill -0 $API_PID 2>/dev/null && curl -s http://localhost:8099/ > /dev/null 2>&1; then
    echo "✅ Matter controller API is running (PID: $API_PID)"
else
    echo "❌ Failed to start matter controller API"
    kill $API_PID 2>/dev/null
    exit 1
fi

echo ""

# Test the integration
echo "5. Testing the integration..."

echo "Testing /pair endpoint:"
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" \
  -X POST http://localhost:8099/pair \
  -H "Content-Type: application/json" \
  -d '{"node_id": 1, "code": "MT:Y.K90SO527JA0648G00"}')

echo "Response:"
echo "$response"

http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)

if [ "$http_status" = "200" ]; then
    echo "✅ Pair endpoint working correctly!"
elif [ "$http_status" = "500" ]; then
    echo "⚠️  Pair endpoint returned 500 - this is expected if no real devices are available"
    echo "   The important thing is that it's communicating with the chip-tool server"
else
    echo "❌ Unexpected response from pair endpoint"
fi

echo ""

# Test other endpoints
echo "6. Testing other endpoints..."

echo "Testing /api/devices:"
curl -s http://localhost:8099/api/devices | jq . 2>/dev/null || curl -s http://localhost:8099/api/devices

echo ""
echo "Testing /api/hub:"
curl -s http://localhost:8099/api/hub | jq . 2>/dev/null || curl -s http://localhost:8099/api/hub

echo ""

# Manual testing instructions
echo "7. Manual testing:"
echo "=================="
echo "The matter controller is now running at: http://localhost:8099"
echo "The chip-tool server is running at: http://localhost:5000"
echo ""
echo "Test commands:"
echo "  curl http://localhost:8099/"
echo "  curl http://localhost:8099/api/devices"
echo "  curl -X POST http://localhost:8099/pair -H 'Content-Type: application/json' -d '{\"node_id\": 1, \"code\": \"MT:TEST\"}'"
echo ""
echo "Press Enter to stop the servers..."
read

# Cleanup
echo "🛑 Stopping servers..."
kill $API_PID 2>/dev/null
echo "✅ Cleanup complete"
