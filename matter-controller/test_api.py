#!/usr/bin/env python3
"""
Test script for Matter Controller API
"""
import requests
import json
import time

API_BASE = "http://localhost:8099"

def test_api():
    """Test the Matter Controller API endpoints."""
    print("🧪 Testing Matter Controller API...")
    
    # Test root endpoint
    try:
        response = requests.get(f"{API_BASE}/")
        if response.status_code == 200:
            print("✅ Root endpoint working")
        else:
            print(f"❌ Root endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error accessing root endpoint: {e}")
        return
    
    # Test token creation
    try:
        token_data = {
            "client_id": "test_client",
            "client_name": "Test Client"
        }
        response = requests.post(f"{API_BASE}/api/token", json=token_data)
        if response.status_code == 200:
            token_info = response.json()
            print(f"✅ Token created: {token_info.get('access_token', 'unknown')[:20]}...")
            token = token_info.get('access_token')
        else:
            print(f"❌ Token creation failed: {response.status_code}")
            token = None
    except Exception as e:
        print(f"❌ Error creating token: {e}")
        token = None
    
    # Set up headers
    headers = {}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    
    # Test devices endpoint
    try:
        response = requests.get(f"{API_BASE}/api/devices", headers=headers)
        if response.status_code == 200:
            devices = response.json()
            print(f"✅ Devices endpoint working: {len(devices)} devices")
        else:
            print(f"❌ Devices endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting devices: {e}")
    
    # Test hub info endpoint
    try:
        response = requests.get(f"{API_BASE}/api/hub", headers=headers)
        if response.status_code == 200:
            hub_info = response.json()
            print(f"✅ Hub info endpoint working: {hub_info.get('status', 'unknown')}")
        else:
            print(f"❌ Hub info endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting hub info: {e}")
    
    # Test analytics endpoint
    try:
        analytics_data = {
            "start_time": None,
            "end_time": None,
            "event_types": None
        }
        response = requests.post(f"{API_BASE}/api/analytics", json=analytics_data, headers=headers)
        if response.status_code == 200:
            analytics = response.json()
            print(f"✅ Analytics endpoint working: {analytics.get('count', 0)} events")
        else:
            print(f"❌ Analytics endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting analytics: {e}")
    
    # Test logs endpoint
    try:
        logs_data = {
            "start_time": None,
            "end_time": None,
            "log_types": None,
            "limit": 10
        }
        response = requests.post(f"{API_BASE}/api/logs", json=logs_data, headers=headers)
        if response.status_code == 200:
            logs = response.json()
            print(f"✅ Logs endpoint working: {logs.get('count', 0)} entries")
        else:
            print(f"❌ Logs endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting logs: {e}")
    
    # Test pair endpoint (this will likely fail without chip-tool server)
    try:
        pair_data = {
            "node_id": 1,
            "code": "MT:Y.K90SO527JA0648G00"
        }
        response = requests.post(f"{API_BASE}/pair", json=pair_data)
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Pair endpoint working: {result.get('message', 'success')}")
        else:
            error_detail = response.json().get('detail', 'Unknown error')
            print(f"⚠️  Pair endpoint failed (expected): {error_detail}")
    except Exception as e:
        print(f"⚠️  Error testing pair endpoint (expected): {e}")
    
    print("🎉 API test completed!")

if __name__ == "__main__":
    test_api()
