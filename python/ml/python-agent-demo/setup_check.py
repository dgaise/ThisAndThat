import os
from pathlib import Path
from dotenv import load_dotenv
import requests
import json

# Load environment variables from ~/.env
env_path = Path.home() / '.env'
load_dotenv(env_path)

# Check if API key exists
api_key = os.getenv('GOOGLE_API_KEY')

if not api_key:
    print("❌ Error: GOOGLE_API_KEY not found in ~/.env")
    exit(1)

print("✓ API key loaded from ~/.env")

# Test with REST API (like curl)
try:
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"
    
    headers = {
        'Content-Type': 'application/json',
        'X-goog-api-key': api_key
    }
    
    data = {
        "contents": [
            {
                "parts": [
                    {"text": "hi"}
                ]
            }
        ]
    }
    
    response = requests.post(url, headers=headers, json=data)
    response.raise_for_status()  # Raise error if status is bad
    
    result = response.json()
    usage = result.get('usageMetadata', {})
    
    print("\nModel Reply:")
    print("environment is ready")
    print(f"Prompt tokens:  {usage.get('promptTokenCount', 'N/A')}")
    print(f"Response tokens: {usage.get('candidatesTokenCount', 'N/A')}")
    
except requests.exceptions.HTTPError as e:
    print(f"❌ Error: {e.response.status_code} - {e.response.text}")
    exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    exit(1)