import google.generativeai as genai
import sys

API_KEY = "AIzaSyB1YL5hTHr2I3Fpys1Jr4rDW2CkP8nwdbQ"
genai.configure(api_key=API_KEY)

print(f"Python version: {sys.version}")
print(f"Library version: {genai.__version__ if hasattr(genai, '__version__') else 'unknown'}")

try:
    print("Listing models...")
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"ID: {m.name}, Display: {m.display_name}")
except Exception as e:
    print(f"Error listing models: {e}")
