import requests
import json

url = "http://localhost:8000/chat/property"
data = {
    "question": "Is this price reasonable?",
    "title": "Cozy 2BHK Apartment",
    "description": "Beautiful apartment near metro",
    "price": 12000,
    "city": "Bangalore",
    "bedrooms": 2,
    "bathrooms": 2,
    "sqft": 1000
}

response = requests.post(url, json=data)
print(f"Status: {response.status_code}")
print(f"Full Response:")
print(json.dumps(response.json(), indent=2))
