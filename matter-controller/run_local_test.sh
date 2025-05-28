#!/bin/bash

# Local Test Runner for Matter Controller
echo "🚀 Matter Controller Local Test Setup"
echo "====================================="

# Check if we're in the right directory
if [ ! -f "config.yaml" ] || [ ! -d "rootfs" ]; then
    echo "❌ Error: Please run this script from the matter-controller directory"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "🔍 Checking dependencies..."

if ! command_exists python3; then
    echo "❌ Python3 is required but not installed"
    exit 1
fi

if ! command_exists pip3; then
    echo "❌ pip3 is required but not installed"
    exit 1
fi

echo "✅ Dependencies check passed"

# Set up environment
echo "⚙️  Setting up environment..."

export LOG_LEVEL=debug
export CHIP_TOOL_SERVER_URL=http://localhost:5000
export CONFIG_PATH=/tmp/matter_controller_options.json
export STARTUP_TIME=$(date +%s)

# Create data directories
mkdir -p /tmp/data/logs
mkdir -p /tmp/data/matter_controller/credentials
mkdir -p /tmp/data/matter_server

# Create mock config file
cat > /tmp/matter_controller_options.json << EOF
{
  "log_level": "debug",
  "token_lifetime_days": 30,
  "allow_external_commissioning": true,
  "analytics_enabled": true,
  "max_log_entries": 1000,
  "max_analytics_events": 1000,
  "auto_register_with_ha": false,
  "chip_tool_server_url": "http://localhost:5000"
}
EOF

# Create mock devices file
cat > /tmp/data/matter_server/devices.json << EOF
{
  "nodes": [
    {
      "node_id": 1,
      "name": "Test Light",
      "vendor_id": 4151,
      "product_id": 20,
      "device_type": "light",
      "commissioned_at": $(date +%s)
    },
    {
      "node_id": 2,
      "name": "Test Switch",
      "vendor_id": 4151,
      "product_id": 21,
      "device_type": "switch",
      "commissioned_at": $(date +%s)
    }
  ]
}
EOF

echo "✅ Environment setup complete"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
cd rootfs/matter_controller

pip3 install --user fastapi uvicorn aiohttp pydantic PyJWT requests > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Python dependencies installed"
else
    echo "❌ Failed to install Python dependencies"
    exit 1
fi

# Function to run tests
run_tests() {
    echo ""
    echo "🧪 Running Tests..."
    echo "=================="
    
    # Test controller
    echo "1. Testing Controller Class..."
    cd ../../
    python3 test_controller.py
    
    echo ""
    echo "2. Starting API Server..."
    cd rootfs/matter_controller
    
    # Start the API server in background
    python3 -m uvicorn api:app --host 0.0.0.0 --port 8099 --log-level debug > /tmp/api_server.log 2>&1 &
    API_PID=$!
    
    echo "🔄 Waiting for API server to start..."
    sleep 5
    
    # Check if server is running
    if kill -0 $API_PID 2>/dev/null; then
        echo "✅ API server started (PID: $API_PID)"
        
        # Test API endpoints
        echo ""
        echo "3. Testing API Endpoints..."
        cd ../../
        python3 test_api.py
        
        echo ""
        echo "4. Manual Testing URLs:"
        echo "   - Web UI: http://localhost:8099"
        echo "   - Health: curl http://localhost:8099/"
        echo "   - Devices: curl http://localhost:8099/api/devices"
        echo "   - Hub Info: curl http://localhost:8099/api/hub"
        echo ""
        echo "5. Test Pairing (will fail without chip-tool server):"
        echo "   curl -X POST http://localhost:8099/pair \\"
        echo "     -H 'Content-Type: application/json' \\"
        echo "     -d '{\"node_id\": 1, \"code\": \"MT:Y.K90SO527JA0648G00\"}'"
        
        echo ""
        echo "📝 Server logs are in: /tmp/api_server.log"
        echo "🔍 To view logs: tail -f /tmp/api_server.log"
        
        echo ""
        echo "⏹️  Press Enter to stop the server..."
        read
        
        # Stop the server
        kill $API_PID 2>/dev/null
        echo "🛑 API server stopped"
        
    else
        echo "❌ Failed to start API server"
        echo "📝 Check logs: cat /tmp/api_server.log"
        exit 1
    fi
}

# Function to run with Docker
run_docker() {
    echo ""
    echo "🐳 Running with Docker..."
    echo "========================"
    
    cd ../../
    
    echo "🔨 Building Docker image..."
    docker build -t matter-controller-test . > /tmp/docker_build.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Docker image built successfully"
        
        echo "🚀 Starting Docker container..."
        docker run -d \
            --name matter-controller-test \
            -p 8099:8099 \
            -p 5580:5580 \
            -e LOG_LEVEL=debug \
            -e CHIP_TOOL_SERVER_URL=http://localhost:5000 \
            -v /tmp/data:/data \
            matter-controller-test > /tmp/docker_run.log 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ Docker container started"
            echo ""
            echo "🔍 Container logs:"
            docker logs matter-controller-test
            
            echo ""
            echo "🌐 Access the API at: http://localhost:8099"
            echo ""
            echo "⏹️  Press Enter to stop and remove the container..."
            read
            
            docker stop matter-controller-test > /dev/null 2>&1
            docker rm matter-controller-test > /dev/null 2>&1
            echo "🛑 Docker container stopped and removed"
        else
            echo "❌ Failed to start Docker container"
            echo "📝 Check logs: cat /tmp/docker_run.log"
        fi
    else
        echo "❌ Failed to build Docker image"
        echo "📝 Check logs: cat /tmp/docker_build.log"
    fi
}

# Main menu
echo ""
echo "Choose how to run the test:"
echo "1. Python directly (recommended for development)"
echo "2. Docker container (recommended for production testing)"
echo "3. Exit"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        run_tests
        ;;
    2)
        run_docker
        ;;
    3)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "🎉 Test completed!"
