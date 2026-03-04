from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from pydantic import BaseModel
import re
import google.generativeai as genai
import traceback
from notifications import start_notification_service

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Start the real-time notification watcher
start_notification_service()

import os

# Configure Gemini API
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyB4BeMYF7wdjoqzeoVb3P8-H4GYoNdMeIU")


if "YOUR_GEMINI_API_KEY" in GEMINI_API_KEY:
    print("⚠️ WARNING: GEMINI_API_KEY is using a placeholder. AI Chat Features will fail.")
else:
    print(f"✅ Gemini API Key configured: {GEMINI_API_KEY[:4]}...{GEMINI_API_KEY[-4:]}")

genai.configure(api_key=GEMINI_API_KEY)

class SearchQuery(BaseModel):
    query: str

@app.get("/")
def home():
    return {"status": "AI service running"}

@app.post("/search/natural-language")
def natural_language_search(data: SearchQuery):
    text = data.query.lower()

    bedrooms = None
    max_price = None
    keywords = []

    # detect BHK
    bhk_match = re.search(r'(\d+)\s*bhk', text)
    if bhk_match:
        bedrooms = int(bhk_match.group(1))

    # detect price
    price_match = re.search(r'(under|below)\s*(\d+)', text)
    if price_match:
        max_price = int(price_match.group(2))

    # simple keyword detection
    if "college" in text:
        keywords.append("college")
    if "student" in text:
        keywords.append("student")

    return {
        "success": True,
        "filters": {
            "bedrooms": bedrooms,
            "max_price": max_price,
            "keywords": keywords
        }
    }

class PriceRequest(BaseModel):
    city: str
    sqft: float
    bedrooms: int
    bathrooms: int

@app.post("/price/predict")
def predict_price(data: PriceRequest):
    # simple heuristic model (acceptable for academic project)

    base_price = 4000

    # bedroom factor
    bedroom_factor = data.bedrooms * 3500

    # size factor
    size_factor = data.sqft * 8

    # bathroom factor
    bathroom_factor = data.bathrooms * 1500

    # city multiplier
    city_multiplier = 1.0
    if data.city.lower() in ["bangalore", "bengaluru"]:
        city_multiplier = 1.8
    elif data.city.lower() in ["chennai"]:
        city_multiplier = 1.5
    elif data.city.lower() in ["coimbatore"]:
        city_multiplier = 1.2

    predicted = (base_price + bedroom_factor + size_factor + bathroom_factor) * city_multiplier

    return {
        "predicted_price": int(predicted)
    }

class PropertyChatRequest(BaseModel):
    question: str
    title: str
    description: str
    price: float
    city: str
    bedrooms: int
    bathrooms: int
    sqft: float

@app.post("/chat/property")
def chat_about_property(data: PropertyChatRequest):
    """
    AI-powered property Q&A using Google Gemini
    """
    try:
        print(f"🤖 Received chat request: {data.question}")
        print(f"Property: {data.title} in {data.city}")
        
        # Use gemini-flash-latest (verified from list_models)
        model = genai.GenerativeModel('gemini-flash-latest')
        
        prompt = f"""You are an AI real estate assistant helping renters make informed decisions.

Property Details:
- Title: {data.title}
- Location: {data.city}
- Price: ₹{data.price}/month
- Size: {data.sqft} sqft
- Bedrooms: {data.bedrooms}
- Bathrooms: {data.bathrooms}
- Description: {data.description}

User Question: {data.question}

Provide a helpful, concise, and practical answer (2-3 sentences max). Focus on being actionable and honest."""

        print("📤 Sending request to Gemini...")
        response = model.generate_content(prompt)
        print(f"✅ Got response from Gemini: {response.text[:100]}...")
        
        return {
            "success": True,
            "reply": response.text
        }
    
    except Exception as e:
        error_details = traceback.format_exc()
        print(f"❌ Error in chat endpoint: {str(e)}")
        print(f"Full traceback:\n{error_details}")
        return {
            "success": False,
            "error": str(e),
            "reply": f"Sorry, I could not process your question. Error: {str(e)}"
        }

class RecommendationRequest(BaseModel):
    user_preferences: str
    available_properties: str  # JSON string of property listings

@app.post("/recommendations")
def get_recommendations(data: RecommendationRequest):
    """
    AI-powered property recommendations based on user preferences.
    """
    try:
        model = genai.GenerativeModel('gemini-flash-latest')
        prompt = f"""You are an expert real estate AI assistant. 
Based on the following user preferences and available properties, recommend the top 3 best matching properties.

User Preferences:
{data.user_preferences}

Available Properties (JSON format):
{data.available_properties}

Analyze the properties and select the best matches. For each selected property, provide:
1. The property ID
2. A brief, personalized explanation (1-2 sentences) of why it's a great fit.

Format the response consistently, extracting the EXACT property ID from the provided data."""
        
        response = model.generate_content(prompt)
        
        return {
            "success": True,
            "recommendations": response.text
        }
    except Exception as e:
        print(f"❌ Error getting recommendations: {str(e)}")
        return {
            "success": False,
            "error": str(e)
        }

