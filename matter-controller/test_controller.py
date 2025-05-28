#!/usr/bin/env python3
"""
Test script for Matter Controller
"""
import asyncio
import os
import sys
import json

# Add the rootfs directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'rootfs', 'matter_controller'))

from controller import MatterController

async def test_controller():
    """Test the Matter Controller functionality."""
    print("🧪 Testing Matter Controller...")
    
    # Set up test environment
    os.environ['CHIP_TOOL_SERVER_URL'] = 'http://localhost:5000'
    
    # Create test data directory
    test_data_dir = "/tmp/test_matter_controller"
    os.makedirs(f"{test_data_dir}/credentials", exist_ok=True)
    os.makedirs(f"{test_data_dir}/logs", exist_ok=True)
    
    # Initialize controller
    controller = MatterController(storage_path=test_data_dir)
    
    print("✅ Controller initialized")
    
    # Test get devices
    try:
        devices = await controller.get_devices()
        print(f"📱 Found {len(devices)} devices")
        for device in devices:
            print(f"  - {device.get('name', 'Unknown')} (ID: {device.get('id', 'Unknown')})")
    except Exception as e:
        print(f"❌ Error getting devices: {e}")
    
    # Test get hub info
    try:
        hub_info = await controller.get_hub_info()
        print(f"🏠 Hub info: {json.dumps(hub_info, indent=2)}")
    except Exception as e:
        print(f"❌ Error getting hub info: {e}")
    
    # Test analytics
    try:
        analytics = await controller.get_analytics()
        print(f"📊 Analytics: {analytics.get('count', 0)} events")
    except Exception as e:
        print(f"❌ Error getting analytics: {e}")
    
    # Test logs
    try:
        logs = await controller.get_logs(limit=5)
        print(f"📝 Recent logs: {logs.get('count', 0)} entries")
        for log in logs.get('entries', [])[:3]:
            print(f"  - {log.get('type', 'unknown')}: {log.get('message', 'no message')}")
    except Exception as e:
        print(f"❌ Error getting logs: {e}")
    
    print("🎉 Controller test completed!")

if __name__ == "__main__":
    asyncio.run(test_controller())
