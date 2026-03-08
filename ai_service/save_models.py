import google.generativeai as genai

API_KEY = "AIzaSyB1YL5hTHr2I3Fpys1Jr4rDW2CkP8nwdbQ"

genai.configure(api_key=API_KEY)

with open("models_list.txt", "w", encoding="utf-8") as f:
    f.write("Available Gemini Models:\n")
    f.write("=" * 60 + "\n\n")
    
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            f.write(f"{m.name}\n")

print("Models saved to models_list.txt")
