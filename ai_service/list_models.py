import google.generativeai as genai

GEMINI_API_KEY = "AIzaSyB1YL5hTHr2I3Fpys1Jr4rDW2CkP8nwdbQ"
genai.configure(api_key=GEMINI_API_KEY)

with open("available_models.txt", "w") as f:
    f.write("Available Gemini models:\n")
    f.write("=" * 50 + "\n\n")
    
    for model in genai.list_models():
        if 'generateContent' in model.supported_generation_methods:
            f.write(f"✅ {model.name}\n")
            f.write(f"   Display Name: {model.display_name}\n")
            f.write(f"   Description: {model.description}\n\n")

print("Model list saved to available_models.txt")
