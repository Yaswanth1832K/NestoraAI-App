import google.generativeai as genai
import sys

API_KEY = "Enter API Key here"

print("Testing Gemini API Key...")
print("=" * 60)

try:
    genai.configure(api_key=API_KEY)
    print("✅ API key configured successfully\n")
    
    print("Attempting to list models...")
    models = list(genai.list_models())
    
    if not models:
        print("❌ No models found! This might mean:")
        print("   - The API key doesn't have access to Gemini")
        print("   - The Generative AI API is not enabled")
        print("   - There's a billing issue")
    else:
        print(f"✅ Found {len(models)} models\n")
        print("Models that support generateContent:")
        for m in models:
            if 'generateContent' in m.supported_generation_methods:
                print(f"  ✓ {m.name}")
        
except Exception as e:
    print(f"❌ Error: {e}")
    print(f"Error type: {type(e).__name__}")
    import traceback
    traceback.print_exc()
